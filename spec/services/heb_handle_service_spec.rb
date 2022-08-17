# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HebHandleService do
  describe '#heb_ids_from_identifier' do
    context "the identifier heb_id entry contains a single HEB ID (vast majority of cases)" do
      let(:identifier) { ['heb_id: heb12345.0001.001'] }
      it 'extracts the HEB ID' do
        expect(described_class.heb_ids_from_identifier(identifier)).to eq(['heb12345.0001.001'])
      end
    end

    context "the identifier heb_id entry contains several HEB IDs (rare)" do
      let(:identifier) { ['heb_id: heb12345.0001.001, heb22345.0001.001, heb33345.0001.001'] }

      it 'extracts all of the HEB IDs' do
        expect(described_class.heb_ids_from_identifier(identifier)).to eq(['heb12345.0001.001',
                                                                           'heb22345.0001.001',
                                                                           'heb33345.0001.001'])
      end
    end
  end

  describe '#find_duplicate_book_ids' do
    before do
      ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: '000000000',
                                      press_sim: 'heb', identifier_tesim: ['heb_id: heb00000.0001.001'] })
      ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: '111111110',
                                      press_sim: 'heb', identifier_tesim: ['heb_id: heb11111.0001.001'] })
      3.times do |index|
        ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: "11111111#{index + 1}",
                                        press_sim: 'heb', identifier_tesim: ['heb_id: heb11111.0001.001'] })
      end
      ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: '222222222',
                                      press_sim: 'heb', identifier_tesim: ['heb_id: heb22222.0001.001', 'heb22233.0001.001'] })
      ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: '333333330',
                                      press_sim: 'heb', identifier_tesim: ['heb_id: heb33333.0001.001, heb33344.0001.001'] })
      3.times do |index|
        ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: "33333333#{index + 1}",
                                        press_sim: 'heb', identifier_tesim: ['heb_id: heb33333.0001.001'] })
      end
      ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: '444444440',
                                      press_sim: 'heb', identifier_tesim: ['heb_id: heb44444.0001.001, heb44441.0001.001'] })
      3.times do |index|
        ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: "44444444#{index + 1}",
                                        press_sim: 'heb', identifier_tesim: ['heb_id: heb44444.0001.001'] })
      end
      3.times do |index|
        ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: "55555555#{index + 1}",
                                        press_sim: 'heb', identifier_tesim: ['heb_id: heb44441.0001.001'] })
      end
      ActiveFedora::SolrService.commit
    end

    context 'when one HEB ID has no matches' do
      it 'finds no matches' do
        expect(described_class.new('000000000').find_duplicate_book_ids.count).to eq(0)
      end
    end

    context 'when one HEB ID has multiple matches' do
      it 'finds the matches' do
        expect(described_class.new('111111110').find_duplicate_book_ids.count).to eq(3)
      end
    end

    context 'when multiple HEB IDs have no matches' do
      it 'finds no matches' do
        expect(described_class.new('222222222').find_duplicate_book_ids.count).to eq(0)
      end
    end

    context 'when one of multiple HEB IDs has matches' do
      it 'finds the matches, excluding the Monograph with the NOID provided' do
        expect(described_class.new('333333330').find_duplicate_book_ids.count).to eq(3)
      end
    end

    context 'when multiple HEB IDs have multiple matches' do
      it 'finds all of the matches' do
        expect(described_class.new('444444440').find_duplicate_book_ids.count).to eq(6)
      end
    end
  end

  context 'handle methods' do
    before do
      ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: '000000000',
                                      press_sim: 'heb', identifier_tesim: ['heb_id: heb12346.0001.001'] })
      ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: '111111110',
                                      press_sim: 'heb', identifier_tesim: ['heb_id: heb11111.0001.001'] })
      ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: '111111120',
                                      press_sim: 'heb', identifier_tesim: ['heb_id: heb11122.0001.001, heb11123.0001.001'] })
      ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: '111111130',
                                      press_sim: 'heb', identifier_tesim: ['heb_id: heb11111.0001.001, heb11124.0001.001'] })
      ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: '111111140',
                                      press_sim: 'heb', identifier_tesim: ['heb_id: heb11111.0001.001, heb22222.0001.001'] })
      # in these two loops we're incrementing the HEB ID *volume* number (middle bit in `heb<title>.<volume>.<book>`)
      2.times do |index|
        ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: "11111111#{index + 1}",
                                        press_sim: 'heb', identifier_tesim: ["heb_id: heb11111.000#{index + 2}.001"] })
      end
      3.times do |index|
        ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: "222222222#{index + 1}",
                                        press_sim: 'heb', identifier_tesim: ["heb_id: heb22222.000#{index + 2}.001"] })
      end

      ActiveFedora::SolrService.commit
    end

    describe '#title_level_handles' do
      context 'when one HEB ID has no title-level matches among other Monographs' do
        it 'points the title-level handle directly to the Monograph' do
          expect(described_class.new('000000000').title_level_handles)
            .to eq({ 'https://hdl.handle.net/2027/heb12346' => 'http://test.host/concern/monographs/000000000' })
        end
      end

      context 'when one HEB ID has multiple title-level matches among other Monographs' do
        it 'points the title-level handle to the volume-level wildcard search' do
          expect(described_class.new('111111110').title_level_handles)
            .to eq({ 'https://hdl.handle.net/2027/heb11111' => 'http://test.host/heb?q=heb11111*' })
        end
      end

      context 'when multiple HEB IDs have no title-level matches among other Monographs' do
        it 'finds no matches and points all title-level handles directly to the Monograph' do
          expect(described_class.new('111111120').title_level_handles)
            .to eq({ 'https://hdl.handle.net/2027/heb11122' => 'http://test.host/concern/monographs/111111120',
                     'https://hdl.handle.net/2027/heb11123' => 'http://test.host/concern/monographs/111111120' })
        end
      end

      context 'when one of multiple HEB IDs has title-level matches among other Monographs' do
        it 'points only the matching title-level handle to the volume-level wildcard search' do
          expect(described_class.new('111111130').title_level_handles)
            .to eq({ 'https://hdl.handle.net/2027/heb11111' => 'http://test.host/heb?q=heb11111*',
                     'https://hdl.handle.net/2027/heb11124' => 'http://test.host/concern/monographs/111111130' })
        end
      end

      context 'when multiple HEB IDs have multiple title-level matches among other Monographs' do
        it 'points all of the matched title-level handles to the volume-level wildcard search' do
          expect(described_class.new('111111140').title_level_handles)
            .to eq({ 'https://hdl.handle.net/2027/heb11111' => 'http://test.host/heb?q=heb11111*',
                     'https://hdl.handle.net/2027/heb22222' => 'http://test.host/heb?q=heb22222*' })
        end
      end
    end

    describe '#book_level_handles' do
      context 'regardless of title-level matching (or anything else)' do
        it 'points the book-level handle directly to the Monograph' do
          expect(described_class.new('000000000').book_level_handles)
            .to eq({ 'https://hdl.handle.net/2027/heb12346.0001.001' => 'http://test.host/concern/monographs/000000000' })
          expect(described_class.new('111111110').book_level_handles)
            .to eq({ 'https://hdl.handle.net/2027/heb11111.0001.001' => 'http://test.host/concern/monographs/111111110' })
          expect(described_class.new('111111120').book_level_handles)
            .to eq({ 'https://hdl.handle.net/2027/heb11122.0001.001' => 'http://test.host/concern/monographs/111111120',
                     'https://hdl.handle.net/2027/heb11123.0001.001' => 'http://test.host/concern/monographs/111111120' })
          expect(described_class.new('111111130').book_level_handles)
            .to eq({ 'https://hdl.handle.net/2027/heb11111.0001.001' => 'http://test.host/concern/monographs/111111130',
                     'https://hdl.handle.net/2027/heb11124.0001.001' => 'http://test.host/concern/monographs/111111130' })
          expect(described_class.new('111111140').book_level_handles)
            .to eq({ 'https://hdl.handle.net/2027/heb11111.0001.001' => 'http://test.host/concern/monographs/111111140',
                     'https://hdl.handle.net/2027/heb22222.0001.001' => 'http://test.host/concern/monographs/111111140' })
        end
      end
    end
  end
end
