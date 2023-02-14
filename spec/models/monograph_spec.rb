# frozen_string_literal: true

require 'rails_helper'

describe Monograph do
  subject { monograph }

  let(:monograph) { described_class.new }
  let(:date) { DateTime.now }
  let(:umich) { build(:press, subdomain: 'umich') }

  it('includes HeliotropeUniverialMetadata') { is_expected.to be_a HeliotropeUniversalMetadata }

  it "has date_published" do
    monograph.date_published = [date]
    expect(monograph.date_published).to eq [date]
  end

  it 'can set the press with a string' do
    monograph.press = umich.subdomain
    expect(monograph.press).to eq umich.subdomain
  end

  it 'must have a press and title' do
    mono = described_class.new
    # note `mono.errors.messages` not populated until `mono.valid?` is called
    expect(mono.valid?).to eq false
    expect(mono.errors.messages[:press]).to eq ['You must select a press.']
    expect(mono.errors.messages[:title]).to eq ['Your work must have a title.']
    mono.press = umich.subdomain
    mono.title = ['blah']
    expect(mono.valid?).to eq true
  end

  context "edition information" do
    it "validates previous_edition and next_edition as a URLs if they are present" do
      monograph.press = umich.subdomain
      monograph.title = ['blah']
      expect(monograph.valid?).to eq true
      monograph.previous_edition = 'blah'
      # note `monograph.errors.messages` not populated until `monograph.valid?` is called
      expect(monograph.valid?).to eq false
      expect(monograph.errors.messages[:previous_edition]).to eq ['must be a url.']
      monograph.previous_edition = 'https://fulcrum.org/concerns/monographs/000000000'
      expect(monograph.valid?).to eq true
      monograph.next_edition = 'blah'
      # note `monograph.errors.messages` not populated until `monograph.valid?` is called
      expect(monograph.valid?).to eq false
      expect(monograph.errors.messages[:next_edition]).to eq ['must be a url.']
      monograph.next_edition = 'https://fulcrum.org/concerns/monographs/111111111'
      expect(monograph.valid?).to eq true
    end
  end

  context 'handles' do
    let(:monograph) { build(:monograph, id: noid) }
    let(:noid) { 'validnoid' }

    before do
      ActiveFedora::Cleaner.clean!
      allow(HandleCreateJob).to receive(:perform_later)
                                  .with(HandleNet::FULCRUM_HANDLE_PREFIX + noid,
                                        Rails.application.routes.url_helpers.hyrax_monograph_url(noid))
      allow(HandleDeleteJob).to receive(:perform_later).with(HandleNet::FULCRUM_HANDLE_PREFIX + noid)
    end

    it 'creates a handle after create and deletes the handle after destroy' do
      monograph.save
      expect(HandleCreateJob).to have_received(:perform_later).with(HandleNet::FULCRUM_HANDLE_PREFIX + noid, Rails.application.routes.url_helpers.hyrax_monograph_url(noid))
      monograph.destroy
      expect(HandleDeleteJob).to have_received(:perform_later).with(HandleNet::FULCRUM_HANDLE_PREFIX + noid)
    end
  end

  it 'validates date_published' do
    mono = described_class.new
    # set up minimum "validates presence" metadata for the Monograph
    expect(mono.valid?).to eq false
    mono.press = umich.subdomain
    mono.title = ['blah']
    expect(mono.valid?).to eq true

    mono.date_published = ['2023/15/15']
    expect(mono.valid?).to eq false
    expect(mono.errors.messages[:date_published]).to eq ["Invalid DateTime value"]
    # this is the format that the `datetime-local` datepicker will provide
    mono.date_published = ['2023-02-03T18:07:53']
    expect(mono.valid?).to eq true
  end

  it 'validates copyright_year' do
    mono = described_class.new
    # set up minimum "validates presence" metadata for the Monograph
    expect(mono.valid?).to eq false
    mono.press = umich.subdomain
    mono.title = ['blah']
    expect(mono.valid?).to eq true

    mono.copyright_year = '202b'
    expect(mono.valid?).to eq false
    expect(mono.errors.messages[:copyright_year]).to eq ["must be in YYYY format"]
    mono.copyright_year = '2023'
    expect(mono.valid?).to eq true
  end

  describe '#maybe_set_date_published' do
    subject { monograph.date_published }

    let(:monograph) { create(:monograph, visibility: visibility, date_published: date_published) }
    let(:visibility) { 'restricted' }
    let(:date_published) { [] }
    let(:now) { Hyrax::TimeService.time_in_utc }
    let(:a_week_ago) { Hyrax::TimeService.time_in_utc - 7.days }
    let(:two_weeks_ago) { Hyrax::TimeService.time_in_utc - 14.days }
    let(:three_weeks_ago) { Hyrax::TimeService.time_in_utc - 21.days }

    before do
      allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(now)
    end

    context 'new Monographs' do
      context 'no specified date_published value' do
        context "with 'restricted' visibility" do
          it 'does not automatically set date_published' do
            monograph.save
            expect(subject).to eq []
          end
        end

        context "with 'open' visibility" do
          let(:visibility) { 'open' }

          it 'automatically sets date_published' do
            monograph.save
            expect(subject).to eq [now]
          end
        end
      end

      context 'date_published value specified' do
        let(:date_published) { [three_weeks_ago] }

        context "with 'restricted' visibility" do
          it 'does not automatically set date_published' do
            monograph.save
            expect(subject).to eq [three_weeks_ago]
          end
        end

        context "with 'open' visibility" do
          let(:visibility) { 'open' }

          it 'does not automatically set date_published to `now`' do
            monograph.save
            expect(subject).to eq [three_weeks_ago]
          end
        end
      end
    end

    context 'existing Monographs' do
      context 'date_published is already set' do
        let(:date_published) { [three_weeks_ago] }

        context 'visibility is not changing' do
          it 'does not automatically set date_published' do
            monograph.title = ['Something New']
            monograph.save
            expect(subject).to eq [three_weeks_ago]
          end

          it 'does not prevent date_published from being set' do
            monograph.title = ['Something New']
            monograph.date_published = [a_week_ago]
            monograph.save
            expect(subject).to eq [a_week_ago]
          end
        end

        context "visibility is changing from 'open' to 'restricted'" do
          # aside: as these Monographs are being created with 'open' visibility, they would have their date_published...
          # values immediately set to `now`, as in the example atop, were they not already set to 'three_weeks_ago'.
          let(:visibility) { 'open' }

          context 'no incoming date_published value' do
            it 'does not set date_published to `now`' do
              monograph.visibility = 'restricted'
              monograph.save
              expect(subject).to eq [three_weeks_ago]
            end
          end

          context 'incoming date_published value' do
            it 'does not set date_published to `now`, uses incoming value' do
              monograph.visibility = 'restricted'
              monograph.date_published = [a_week_ago]
              monograph.save
              expect(subject).to eq [a_week_ago]
            end
          end
        end

        context "visibility is changing from 'restricted' to 'open'" do
          context 'no incoming date_published value' do
            it 'does not set date_published as it is already populated' do
              monograph.visibility = 'open'
              monograph.save
              expect(subject).to eq [three_weeks_ago]
            end
          end

          context 'incoming date_published value' do
            it 'does not set date_published to `now`, uses incoming value' do
              monograph.visibility = 'open'
              monograph.date_published = [a_week_ago]
              monograph.save
              expect(subject).to eq [a_week_ago]
            end
          end
        end
      end

      context 'date_published is not yet set' do
        context 'visibility is not changing' do
          context 'no incoming date_published value' do
            it 'does not automatically set date_published' do
              monograph.title = ['Something New']
              monograph.save
              expect(subject).to eq []
            end
          end

          context 'incoming date_published value' do
            it 'does not set date_published to `now`, uses incoming value' do
              monograph.title = ['Something New']
              monograph.date_published = [a_week_ago]
              monograph.save
              expect(subject).to eq [a_week_ago]
            end
          end
        end

        context "visibility is changing from 'open' to 'restricted'" do
          # aside: as these Monographs are being created with 'open' visibility, they would have their date_published...
          # values set to `now` straight away, as in the example above, were we to not set them to 'two_weeks_ago' here.
          let(:visibility) { 'open' }
          let(:date_published) { [two_weeks_ago] }

          context 'no incoming date_published value' do
            it 'does not set date_published to `now`' do
              monograph.visibility = 'restricted'
              monograph.save
              expect(subject).to eq [two_weeks_ago]
            end
          end

          context 'there is an incoming date_published value' do
            it 'does not set date_published to `now`, uses incoming value' do
              monograph.visibility = 'restricted'
              monograph.date_published = [a_week_ago]
              monograph.save
              expect(subject).to eq [a_week_ago]
            end
          end
        end

        context "visibility is changing from 'restricted' to 'open'" do
          context 'no incoming date_published value' do
            it 'sets date_published to `now`' do
              monograph.visibility = 'open'
              monograph.save
              expect(subject).to eq [now]
            end
          end

          context 'there is an incoming date_published value' do
            it 'does not set date_published to `now`, uses incoming value' do
              monograph.visibility = 'open'
              monograph.date_published = [a_week_ago]
              monograph.save
              expect(subject).to eq [a_week_ago]
            end
          end
        end
      end
    end
  end
end
