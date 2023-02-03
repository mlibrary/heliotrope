# frozen_string_literal: true

require 'rails_helper'

describe FileSet do
  let(:file_set) { described_class.new }
  let(:sort_date) { '2014-01-03' }
  let(:bad_sort_date) { 'NOT-A-DATE' }

  it 'has a valid sort_date' do
    file_set.sort_date = sort_date
    file_set.apply_depositor_metadata('admin@example.com')
    expect(file_set.save!).to be true
    expect(file_set.reload.sort_date).to eq sort_date
  end

  it 'does not have an valid sort date' do
    file_set.sort_date = bad_sort_date
    file_set.apply_depositor_metadata('admin@example.com')
    expect { file_set.save! }.to raise_error(ActiveFedora::RecordInvalid)
  end

  describe 'property :content_type' do
    context 'attribute' do
      subject { described_class.delegated_attributes[:content_type] }

      it 'is a multiple' do
        expect(subject.multiple).to be true
      end
    end

    context 'index configuration' do
      subject { described_class.index_config[:content_type] }

      it 'is stored searchable' do
        expect(subject.behaviors).to include(:stored_searchable)
      end
      it 'is facetable' do
        expect(subject.behaviors).to include(:facetable)
      end
      it 'is a string' do
        expect(subject.data_type).to eq :string
      end
    end

    context 'predicate' do
      subject { described_class.reflect_on_property(:content_type) }

      it 'is SCHEMA.contentType' do
        expect(subject.predicate).to eq ::RDF::Vocab::SCHEMA.contentType
      end
    end
  end

  context 'handles' do
    let(:file_set) { build(:file_set, id: noid) }
    let(:noid) { 'validnoid' }

    before do
      ActiveFedora::Cleaner.clean!
      allow(HandleCreateJob).to receive(:perform_later)
                                  .with(HandleNet::FULCRUM_HANDLE_PREFIX + noid,
                                        Rails.application.routes.url_helpers.hyrax_file_set_url(noid))
      allow(HandleDeleteJob).to receive(:perform_later).with(HandleNet::FULCRUM_HANDLE_PREFIX + noid)
    end

    it 'creates a handle after create and deletes the handle after destroy' do
      file_set.save
      expect(HandleCreateJob)
        .to have_received(:perform_later)
              .with(HandleNet::FULCRUM_HANDLE_PREFIX + noid, Rails.application.routes.url_helpers.hyrax_file_set_url(noid))
      file_set.destroy
      expect(HandleDeleteJob).to have_received(:perform_later).with(HandleNet::FULCRUM_HANDLE_PREFIX + noid)
    end
  end

  describe 'shortcut methods for mime types' do
    let(:file_set) { create(:file_set) }

    context 'video?' do
      subject { file_set.video? }

      before do
        allow(file_set).to receive(:mime_type).and_return('video/mpg')
      end

      it 'returns true for a mime type of `video/mpg`' do
        expect(subject).to be true
      end

      before do
        allow(file_set).to receive(:mime_type).and_return('video/x-m4v')
      end

      it 'returns true for a mime type of `video/x-m4v`' do
        expect(subject).to be true
      end
    end
  end

  describe '#maybe_set_date_published' do
    subject { file_set.date_published }

    let(:file_set) { create(:file_set, visibility: visibility, date_published: date_published) }
    let(:visibility) { 'restricted' }
    let(:date_published) { [] }
    let(:now) { Hyrax::TimeService.time_in_utc }
    let(:a_week_ago) { Hyrax::TimeService.time_in_utc - 7.days }
    let(:two_weeks_ago) { Hyrax::TimeService.time_in_utc - 14.days }
    let(:three_weeks_ago) { Hyrax::TimeService.time_in_utc - 21.days }

    before do
      allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(now)
    end

    context 'new FileSets' do
      context 'no specified date_published value' do
        context "with 'restricted' visibility" do
          it 'does not automatically set date_published' do
            file_set.save
            expect(subject).to eq []
          end
        end

        context "with 'open' visibility" do
          let(:visibility) { 'open' }

          it 'automatically sets date_published' do
            file_set.save
            expect(subject).to eq [now]
          end
        end
      end

      context 'date_published value specified' do
        let(:date_published) { [three_weeks_ago] }

        context "with 'restricted' visibility" do
          it 'does not automatically set date_published' do
            file_set.save
            expect(subject).to eq [three_weeks_ago]
          end
        end

        context "with 'open' visibility" do
          let(:visibility) { 'open' }

          it 'does not automatically set date_published to `now`' do
            file_set.save
            expect(subject).to eq [three_weeks_ago]
          end
        end
      end
    end

    context 'existing FileSets' do
      context 'date_published is already set' do
        let(:date_published) { [three_weeks_ago] }

        context 'visibility is not changing' do
          it 'does not automatically set date_published' do
            file_set.title = ['Something New']
            file_set.save
            expect(subject).to eq [three_weeks_ago]
          end

          it 'does not prevent date_published from being set' do
            file_set.title = ['Something New']
            file_set.date_published = [a_week_ago]
            file_set.save
            expect(subject).to eq [a_week_ago]
          end
        end

        context "visibility is changing from 'open' to 'restricted'" do
          # aside: as these FileSets are being created with 'open' visibility, they would have their date_published...
          # values immediately set to `now`, as in the example atop, were they not already set to 'three_weeks_ago'.
          let(:visibility) { 'open' }

          context 'no incoming date_published value' do
            it 'does not set date_published to `now`' do
              file_set.visibility = 'restricted'
              file_set.save
              expect(subject).to eq [three_weeks_ago]
            end
          end

          context 'incoming date_published value' do
            it 'does not set date_published to `now`, uses incoming value' do
              file_set.visibility = 'restricted'
              file_set.date_published = [a_week_ago]
              file_set.save
              expect(subject).to eq [a_week_ago]
            end
          end
        end

        context "visibility is changing from 'restricted' to 'open'" do
          context 'no incoming date_published value' do
            it 'does not set date_published as it is already populated' do
              file_set.visibility = 'open'
              file_set.save
              expect(subject).to eq [three_weeks_ago]
            end
          end

          context 'incoming date_published value' do
            it 'does not set date_published to `now`, uses incoming value' do
              file_set.visibility = 'open'
              file_set.date_published = [a_week_ago]
              file_set.save
              expect(subject).to eq [a_week_ago]
            end
          end
        end
      end

      context 'date_published is not yet set' do
        context 'visibility is not changing' do
          context 'no incoming date_published value' do
            it 'does not automatically set date_published' do
              file_set.title = ['Something New']
              file_set.save
              expect(subject).to eq []
            end
          end

          context 'incoming date_published value' do
            it 'does not set date_published to `now`, uses incoming value' do
              file_set.title = ['Something New']
              file_set.date_published = [a_week_ago]
              file_set.save
              expect(subject).to eq [a_week_ago]
            end
          end
        end

        context "visibility is changing from 'open' to 'restricted'" do
          # aside: as these FileSets are being created with 'open' visibility, they would have their date_published...
          # values set to `now` straight away, as in the example above, were we to not set them to 'two_weeks_ago' here.
          let(:visibility) { 'open' }
          let(:date_published) { [two_weeks_ago] }

          context 'no incoming date_published value' do
            it 'does not set date_published to `now`' do
              file_set.visibility = 'restricted'
              file_set.save
              expect(subject).to eq [two_weeks_ago]
            end
          end

          context 'there is an incoming date_published value' do
            it 'does not set date_published to `now`, uses incoming value' do
              file_set.visibility = 'restricted'
              file_set.date_published = [a_week_ago]
              file_set.save
              expect(subject).to eq [a_week_ago]
            end
          end
        end

        context "visibility is changing from 'restricted' to 'open'" do
          context 'no incoming date_published value' do
            it 'sets date_published to `now`' do
              file_set.visibility = 'open'
              file_set.save
              expect(subject).to eq [now]
            end
          end

          context 'there is an incoming date_published value' do
            it 'does not set date_published to `now`, uses incoming value' do
              file_set.visibility = 'open'
              file_set.date_published = [a_week_ago]
              file_set.save
              expect(subject).to eq [a_week_ago]
            end
          end
        end
      end
    end
  end
end
