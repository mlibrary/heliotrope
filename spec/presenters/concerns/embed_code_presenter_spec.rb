# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbedCodePresenter do
  let(:ability) { double('ability') }
  let(:presenter) { Hyrax::FileSetPresenter.new(file_set_doc, ability) }
  let(:dimensionless_presenter) { Hyrax::FileSetPresenter.new(file_set_doc, ability) }

  describe '#allow_embed?' do
    let(:press) { create(:press) }
    let(:monograph) { create(:monograph, press: press.subdomain) }
    let(:file_set) { create(:file_set) }
    let(:file_set_doc) { SolrDocument.new(file_set.to_solr) }

    before do
      monograph.ordered_members << file_set
      monograph.save!
    end

    context 'no' do
      before { allow(ability).to receive(:platform_admin?).and_return(false) }

      it { expect(presenter.allow_embed?).to be false }
    end

    context 'yes' do
      before { allow(ability).to receive(:platform_admin?).and_return(true) }

      it { expect(presenter.allow_embed?).to be true }
    end
  end

  describe '#embeddable_type?' do
    subject { presenter.embeddable_type? }

    let(:file_set_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], mime_type_ssi: mime_type, resource_type_tesim: [resource_type]) }
    let(:mime_type) { nil }
    let(:resource_type) { nil }

    context 'map' do
      let(:resource_type) { 'map' }

      it { is_expected.to be false }
    end

    context 'interactive map' do
      let(:resource_type) { 'interactive map' }

      it { is_expected.to be true }
    end

    context 'image' do
      let(:mime_type) { 'image/tiff' }

      it { is_expected.to be true }
    end

    context 'video' do
      let(:mime_type) { 'video/mp4' }

      it { is_expected.to be true }
    end

    context 'audio' do
      let(:mime_type) { 'audio/mp3' }

      it { is_expected.to be true }
    end

    context 'pdf' do
      let(:mime_type) { 'application/pdf' }

      it { is_expected.to be false }
    end

    context 'Word .doc' do
      let(:mime_type) { 'application/msword' }

      it { is_expected.to be false }
    end
  end

  describe '#embed_code' do
    let(:map_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1920px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:60%; position:relative; height:0;'><!-- actual height: 1080px -->
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:dimensionless_map_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:400px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:60%; position:relative; height:0;'>
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:image_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1920px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:60%; position:relative; height:0;'><!-- actual image height: 1080px -->
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:portrait_image_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1080px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:80%; position:relative; height:0;'><!-- actual image height: 1920px -->
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:square_image_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:500px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:80%; position:relative; height:0;'><!-- actual image height: 500px -->
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:dimensionless_image_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:400px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:60%; position:relative; height:0;'>
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:video_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1920px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:56.25%; position:relative; height:0;'><!-- actual video height: 1080px -->
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:dimensionless_video_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:400px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:75%; position:relative; height:0;'>
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:video_with_visual_descriptions_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1920px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:67.5%; position:relative; height:0;'><!-- actual video height: 1080px -->
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:audio_embed_code) {
      "<iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; display:block; overflow:hidden; border-width:0; width:98%; max-width:98%; height:125px; margin:auto'></iframe>"
    }
    let(:file_set_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], mime_type_ssi: mime_type, resource_type_tesim: [resource_type], transcript_tesim: transcript) }
    let(:mime_type) { nil }
    let(:resource_type) { nil }
    let(:transcript) { nil }

    before do
      allow(presenter).to receive(:width).and_return(1920)
      allow(presenter).to receive(:height).and_return(1080)
      allow(dimensionless_presenter).to receive(:width).and_return('')
      allow(dimensionless_presenter).to receive(:height).and_return('')
    end

    context 'map FileSet' do
      let(:resource_type) { 'interactive map' }

      it { expect(presenter.embed_code).to eq map_embed_code }
    end

    context 'image FileSet (landscape)' do
      let(:mime_type) { 'image/tiff' }

      it { expect(presenter.embed_code).to eq image_embed_code }
    end

    context 'image FileSet (portrait)' do
      before do
        allow(presenter).to receive(:width).and_return(1080)
        allow(presenter).to receive(:height).and_return(1920)
      end

      let(:mime_type) { 'image/tiff' }

      it { expect(presenter.embed_code).to eq portrait_image_embed_code }
    end

    context 'image FileSet (square)' do
      before do
        allow(presenter).to receive(:width).and_return(500)
        allow(presenter).to receive(:height).and_return(500)
      end

      let(:mime_type) { 'image/tiff' }

      it { expect(presenter.embed_code).to eq square_image_embed_code }
    end

    context 'video FileSet' do
      let(:mime_type) { 'video/mp4' }

      it { expect(presenter.embed_code).to eq video_embed_code }
    end

    context 'dimensionless map FileSet' do
      let(:resource_type) { 'interactive map' }

      it { expect(dimensionless_presenter.embed_code).to eq dimensionless_map_embed_code }
    end

    context 'dimensionless image FileSet' do
      let(:mime_type) { 'image/tiff' }

      it { expect(dimensionless_presenter.embed_code).to eq dimensionless_image_embed_code }
    end

    context 'dimensionless video FileSet' do
      let(:mime_type) { 'video/mp4' }

      it { expect(dimensionless_presenter.embed_code).to eq dimensionless_video_embed_code }
    end

    context 'video with visual descriptions FileSet' do
      let(:mime_type) { 'video/mp4' }

      before do
        allow(presenter).to receive(:visual_descriptions).and_return('blah')
      end

      it { expect(presenter.embed_code).to eq video_with_visual_descriptions_embed_code }
    end

    context 'audio FileSet' do
      let(:mime_type) { 'audio/mp3' }

      context 'no transcript present' do
        it { expect(presenter.embed_code).to eq audio_embed_code }
      end

      context 'transcript present' do
        let(:transcript) { ['STUFF'] }

        it { expect(presenter.embed_code).to eq audio_embed_code }
      end
    end

    context '#audio_without_transcript?' do
      context 'audio file' do
        let(:mime_type) { 'audio/mp3' }

        context 'no transcript present' do
          it { expect(presenter.audio_without_transcript?).to eq true }
        end

        context 'transcript present' do
          let(:transcript) { ['STUFF'] }

          it { expect(presenter.audio_without_transcript?).to eq false }
        end
      end

      context 'non-audio file' do
        let(:mime_type) { 'blerg' }

        context 'no transcript present' do
          it { expect(presenter.audio_without_transcript?).to eq false }
        end

        context 'transcript present' do
          let(:transcript) { ['STUFF'] }

          it { expect(presenter.audio_without_transcript?).to eq false }
        end
      end
    end
  end
end
