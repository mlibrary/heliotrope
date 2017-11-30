# frozen_string_literal: true

require 'nokogiri'

RSpec.describe EPub::Search do
  describe '#search' do
    before(:all) do # rubocop:disable RSpec/BeforeAfterAll
      @id = 'validnoid'
      @file = './spec/fixtures/fake_epub01.epub'
      EPub::Publication.from(id: @id, file: @file)
    end
    after(:all) { EPub::Publication.from(@id).purge } # rubocop:disable RSpec/BeforeAfterAll

    subject { described_class.new(EPub::Publication.from(@id)).search(query) }

    context 'db results empty' do
      let(:query) { 'nobody' }
      it { is_expected.to match(q: query) }
    end

    context 'db results non empty' do
      let(:query) { 'everybody' }
      it do
        expect(subject[:q]).to eq "everybody"
        expect(subject[:search_results].length).to eq 2

        expect(subject[:search_results][0][:cfi]).to eq "/6/2[Chapter01]!/4/8,/1:23,/1:32"
        expect(subject[:search_results][0][:title]).to eq "Damage report!"
        expect(subject[:search_results][0][:snippet]).to eq "Why don't we just give everybody a promotion and call it a night - 'Commander'?"

        expect(subject[:search_results][1][:cfi]).to eq "/6/6[Chapter03]!/4/12,/1:781,/1:790"
        expect(subject[:search_results][1][:title]).to eq "Mr. Crusher, ready a collision course with the Borg ship."
        expect(subject[:search_results][1][:snippet]).to eq "Why don't we just give everybody a promotion and call it a night - 'Commander'?"
      end
    end
  end

  describe "#node_query_match" do
    subject { described_class.new(double("publication")) }
    let(:doc) { Nokogiri::XML("<html><body><p>We will match search.</p><p>We will not match searched.<p></body></html>") }

    context "when looking for 'search' it matches 'search'" do
      let(:node) { doc.xpath("//p")[0].children[0] }
      let(:query) { "search" }
      it { expect(subject.node_query_match(node, query)).to eq 14 }
    end

    context "when looking for 'search' it will not match 'searched'" do
      let(:node) { doc.xpath("//p")[1].children[0] }
      let(:query) { "search" }
      it { expect(subject.node_query_match(node, query)).to eq nil }
    end
  end
end
