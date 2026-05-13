# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PdfAccessibilityMetadataPresenter do
  let(:solr_document) { SolrDocument.new({ 'pdf_a11y_access_mode_ssim' => pdf_a11y_access_mode_ssim,
                                           'pdf_a11y_accessibility_feature_ssim' => pdf_a11y_accessibility_feature_ssim,
                                           'pdf_a11y_conforms_to_ssi' => pdf_a11y_conforms_to_ssi,
                                           'pdf_a11y_screen_reader_friendly_ssi' => pdf_a11y_screen_reader_friendly_ssi }) }

  let(:pdf_a11y_access_mode_ssim) { ['textual', 'visual'] }
  let(:pdf_a11y_accessibility_feature_ssim) { ['Bookmarks', 'Machine-readable text (Embedded)', 'Tagged structure'] }
  let(:pdf_a11y_conforms_to_ssi) { 'PDF/UA-1' }
  let(:pdf_a11y_screen_reader_friendly_ssi) { 'yes' }
  let(:presenter) { described_class.new(solr_document) }

  describe '#a11y_format' do
    subject { presenter.a11y_format }

    context 'reader_ebook_format_sim is indexed' do
      let(:solr_document) { SolrDocument.new('reader_ebook_format_sim' => 'PDF') }

      it 'returns the indexed value' do
        is_expected.to eq 'PDF'
      end
    end

    context 'reader_ebook_format_sim is not indexed' do
      it 'falls back to "PDF"' do
        is_expected.to eq 'PDF'
      end
    end
  end

  describe '#a11y_screen_reader_friendly' do
    subject { presenter.a11y_screen_reader_friendly }

    context 'pdf_a11y_screen_reader_friendly_ssi is "yes"' do
      it 'outputs the field value' do
        is_expected.to eq 'yes'
      end
    end

    context 'pdf_a11y_screen_reader_friendly_ssi is "no, but includes some accessibility features"' do
      let(:pdf_a11y_screen_reader_friendly_ssi) { 'no, but includes some accessibility features' }

      it 'outputs the field value' do
        is_expected.to eq 'no, but includes some accessibility features'
      end
    end

    context 'pdf_a11y_screen_reader_friendly_ssi is "no"' do
      let(:pdf_a11y_screen_reader_friendly_ssi) { 'no' }

      it 'outputs the field value' do
        is_expected.to eq 'no'
      end
    end

    context 'pdf_a11y_screen_reader_friendly_ssi is not present' do
      let(:pdf_a11y_screen_reader_friendly_ssi) { nil }

      it 'outputs "No information is available"' do
        is_expected.to eq 'No information is available'
      end
    end
  end

  describe '#a11y_accessibility_summary' do
    subject { presenter.a11y_accessibility_summary }

    it 'returns nil (not yet implemented for PDFs)' do
      is_expected.to be_nil
    end
  end

  describe '#a11y_conforms_to' do
    subject { presenter.a11y_conforms_to }

    it 'outputs the plain string value as-is' do
      is_expected.to eq 'PDF/UA-1'
    end

    context 'pdf_a11y_conforms_to_ssi is not present' do
      let(:pdf_a11y_conforms_to_ssi) { nil }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#a11y_certified_by' do
    subject { presenter.a11y_certified_by }

    it 'returns nil (not yet implemented for PDFs)' do
      is_expected.to be_nil
    end
  end

  describe '#a11y_certifier_credential' do
    subject { presenter.a11y_certifier_credential }

    it 'returns nil (not yet implemented for PDFs)' do
      is_expected.to be_nil
    end
  end

  describe '#a11y_accessibility_hazards' do
    subject { presenter.a11y_accessibility_hazards }

    it 'returns nil (not applicable for PDFs)' do
      is_expected.to be_nil
    end
  end

  describe '#a11y_accessibility_features' do
    subject { presenter.a11y_accessibility_features }

    it 'outputs the field values' do
      is_expected.to eq ['Bookmarks', 'Machine-readable text (Embedded)', 'Tagged structure']
    end

    context 'pdf_a11y_accessibility_feature_ssim contains duplicates' do
      let(:pdf_a11y_accessibility_feature_ssim) { ['Bookmarks', 'Bookmarks', 'Tagged structure'] }

      it 'de-duplicates the values' do
        is_expected.to eq ['Bookmarks', 'Tagged structure']
      end
    end

    context 'pdf_a11y_accessibility_feature_ssim is not present' do
      let(:pdf_a11y_accessibility_feature_ssim) { nil }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#a11y_access_modes' do
    subject { presenter.a11y_access_modes }

    it 'outputs the correct field value' do
      is_expected.to eq ['textual', 'visual']
    end
  end

  describe '#a11y_access_modes_sufficient' do
    subject { presenter.a11y_access_modes_sufficient }

    it 'returns nil (cannot be determined from available PDF data)' do
      is_expected.to be_nil
    end
  end


  describe '#prepopulated_link_for_accessible_copy_request_form' do
    subject { presenter.prepopulated_link_for_accessible_copy_request_form }

    context 'only id is available' do
      let(:solr_document) { SolrDocument.new(id: '999999999') }

      it 'only pre-populates the URL with the ID' do
        is_expected.to eq "https://umich.qualtrics.com/jfe/form/SV_8AiVezqglaUnQZo?noid=#{solr_document.id}"
      end
    end

    context 'id and press are available' do
      let(:solr_document) { SolrDocument.new(id: '999999999', 'press_tesim' => ['blah-press']) }

      it 'pre-populates the URL with ID and press' do
        is_expected.to eq "https://umich.qualtrics.com/jfe/form/SV_8AiVezqglaUnQZo?noid=999999999&press=blah-press"
      end
    end

    context 'id, press and title are available' do
      let(:solr_document) { SolrDocument.new(id: '999999999',
                                             'press_tesim' => ['blah-press'],
                                             'title_tesim' => ['A Fantastic Title: Stuff']) }

      it 'pre-populates the URL with ID, press and title' do
        is_expected.to eq "https://umich.qualtrics.com/jfe/form/SV_8AiVezqglaUnQZo?noid=999999999&press=blah-press" \
                          "&Q_PopulateResponse={%22QID3%22:%22A+Fantastic+Title%3A+Stuff%22}"
      end
    end

    context 'id, press, title and creator are available' do
      let(:solr_document) { SolrDocument.new(id: '999999999',
                                             'press_tesim' => ['blah-press'],
                                             'title_tesim' => ['A Fantastic Title: Stuff'],
                                             'creator_full_name_tesim' => ['First, Author']) }

      it 'pre-populates the URL with ID, press, title and creator' do
        is_expected.to eq "https://umich.qualtrics.com/jfe/form/SV_8AiVezqglaUnQZo?noid=999999999&press=blah-press" \
                          "&Q_PopulateResponse={%22QID3%22:%22A+Fantastic+Title%3A+Stuff%22," \
                          "%22QID4%22:%22First%2C+Author%22}"
      end
    end

    context 'id, press, title, creator and isbn are available' do
      let(:solr_document) { SolrDocument.new(id: '999999999',
                                             'press_tesim' => ['blah-press'],
                                             'title_tesim' => ['A Fantastic Title: Stuff'],
                                             'creator_full_name_tesim' => ['First, Author'],
                                             'isbn_tesim' => ['978-0-472-12665-1 (ebook)', '978-0-472-13189-1 (hardcover)']) }

      it 'pre-populates the URL with ID, press, title, creator and the first isbn' do
        is_expected.to eq "https://umich.qualtrics.com/jfe/form/SV_8AiVezqglaUnQZo?noid=999999999&press=blah-press" \
                          "&Q_PopulateResponse={" \
                          "%22QID3%22:%22A+Fantastic+Title%3A+Stuff%22," \
                          "%22QID4%22:%22First%2C+Author%22," \
                          "%22QID5%22:%22978-0-472-12665-1+%28ebook%29%22}"
      end
    end

    context 'id, press, title, creator, isbn and publisher are available' do
      let(:solr_document) { SolrDocument.new(id: '999999999',
                                             'press_tesim' => ['blah-press'],
                                             'title_tesim' => ['A Fantastic Title: Stuff'],
                                             'creator_full_name_tesim' => ['First, Author'],
                                             'isbn_tesim' => ['978-0-472-12665-1 (ebook)', '978-0-472-13189-1 (hardcover)'],
                                             'publisher_tesim' => 'Blah Press Publishing Company') }

      it 'pre-populates the URL with ID, press, title, creator, the first isbn and publisher' do
        is_expected.to eq "https://umich.qualtrics.com/jfe/form/SV_8AiVezqglaUnQZo?noid=999999999&press=blah-press" \
                          "&Q_PopulateResponse={" \
                          "%22QID3%22:%22A+Fantastic+Title%3A+Stuff%22," \
                          "%22QID4%22:%22First%2C+Author%22," \
                          "%22QID5%22:%22978-0-472-12665-1+%28ebook%29%22," \
                          "%22QID14%22:%22Blah+Press+Publishing+Company%22}"
      end
    end
  end
end
