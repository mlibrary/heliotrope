# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Keycard::CachedInstitutionFinder do
  subject(:finder) { described_class.new(db: db, cache_size: 10, cache_ttl: 60) }

  let(:db) { Keycard::DB.initialize! }
  let(:request) { double('request', client_ip: '127.0.0.1') }
  # 127.0.0.1
  let(:localhost) { 2_130_706_433 }

  def insert_network(inst:, switch: 'allow', deleted: 'f', id: inst)
    db.execute <<~SQL.squish
      insert into aa_network
        (uniqueIdentifier, dlpsCIDRAddress, dlpsAddressStart, dlpsAddressEnd, dlpsAccessSwitch, inst, lastModifiedBy, dlpsDeleted)
      values
        ('#{id}', '127.0.0.1/32', '#{localhost}', '#{localhost}', '#{switch}', '#{inst}', 'root', '#{deleted}')
    SQL
  end

  before { db.execute "delete from aa_network" }

  after { db.execute "delete from aa_network" }

  describe '#attributes_for' do
    context 'when the ip matches no networks' do
      it { expect(finder.attributes_for(request)).to eq({}) }
    end

    context 'when the ip is not a valid address' do
      let(:request) { double('request', client_ip: 'not-an-ip') }

      it { expect(finder.attributes_for(request)).to eq({}) }
    end

    context 'when there is no client ip at all' do
      let(:request) { double('request', client_ip: nil) }

      it { expect(finder.attributes_for(request)).to eq({}) }
    end

    context 'when the ip matches an allowed network' do
      before { insert_network(inst: 42) }

      it { expect(finder.attributes_for(request)).to eq(dlpsInstitutionId: [42]) }
    end

    context 'when the ip matches a deleted network' do
      before { insert_network(inst: 42, deleted: 't') }

      it { expect(finder.attributes_for(request)).to eq({}) }
    end

    context 'when an institution is both allowed and denied for the ip' do
      before do
        insert_network(inst: 42, id: 1)
        insert_network(inst: 42, id: 2, switch: 'deny')
      end

      it 'excludes the denied institution' do
        expect(finder.attributes_for(request)).to eq({})
      end
    end

    it 'does not hold a prepared statement' do
      # The bug this class exists to avoid: Keycard::InstitutionFinder keeps a
      # Mysql2::Statement for the life of the process, and executing a stale one
      # raises "Commands out of sync; you can't run this command now".
      expect(finder.send(:stmt)).to be_nil
    end
  end

  describe 'caching' do
    before { insert_network(inst: 42) }

    it 'queries the database only once for a repeated ip' do
      expect(db).to receive(:[]).once.and_call_original

      3.times { expect(finder.attributes_for(request)).to eq(dlpsInstitutionId: [42]) }
    end

    it 'queries the database once per distinct ip' do
      other = double('request', client_ip: '127.0.0.2')

      expect(db).to receive(:[]).twice.and_call_original

      finder.attributes_for(request)
      finder.attributes_for(other)
      finder.attributes_for(request)
    end

    it 'caches negative results' do
      db.execute "delete from aa_network"

      expect(db).to receive(:[]).once.and_call_original

      2.times { expect(finder.attributes_for(request)).to eq({}) }
    end

    it 'does not cache a failed lookup' do
      allow(db).to receive(:[]).and_raise(Sequel::DatabaseDisconnectError, 'boom')

      expect { finder.attributes_for(request) }.to raise_error(Sequel::DatabaseDisconnectError)

      allow(db).to receive(:[]).and_call_original
      expect(finder.attributes_for(request)).to eq(dlpsInstitutionId: [42])
    end

    it 'returns a frozen list so callers cannot corrupt the cache' do
      expect(finder.attributes_for(request)[:dlpsInstitutionId]).to be_frozen
    end

    describe '#clear_cache' do
      it 'forces the next lookup to hit the database' do
        expect(finder.attributes_for(request)).to eq(dlpsInstitutionId: [42])

        db.execute "delete from aa_network"
        expect(finder.attributes_for(request)).to eq(dlpsInstitutionId: [42])

        finder.clear_cache
        expect(finder.attributes_for(request)).to eq({})
      end
    end

    context 'with an expired ttl' do
      subject(:finder) { described_class.new(db: db, cache_size: 10, cache_ttl: 0) }

      it 'looks the ip up again' do
        expect(finder.attributes_for(request)).to eq(dlpsInstitutionId: [42])

        db.execute "delete from aa_network"
        expect(finder.attributes_for(request)).to eq({})
      end
    end

    context 'when the cache is smaller than the number of distinct ips' do
      subject(:finder) { described_class.new(db: db, cache_size: 1, cache_ttl: 60) }

      it 'evicts the least recently used entry' do
        other = double('request', client_ip: '127.0.0.2')

        expect(db).to receive(:[]).exactly(3).times.and_call_original

        finder.attributes_for(request)
        finder.attributes_for(other)
        finder.attributes_for(request)
      end
    end
  end

  describe '#identity_keys' do
    it { expect(finder.identity_keys).to eq [:dlpsInstitutionId] }
  end

  # Guards the wiring in config/initializers/services.rb. If someone reverts to
  # the stock Keycard::InstitutionFinder, the prepared statement -- and with it
  # HELIO-4633 -- comes back.
  describe 'application wiring' do
    it 'registers this finder rather than the gem default' do
      expect(Services.institution_finder).to be_a described_class
    end

    it 'reuses one finder, and therefore one cache, per process' do
      expect(Services.institution_finder).to equal Services.institution_finder
    end

    it 'builds request attributes from that finder' do
      expect(Services.request_attributes).to be_a Keycard::Request::MemoizingAttributesFactory
      expect(Services.request_attributes.send(:finders)).to eq [Services.institution_finder]
    end
  end
end
