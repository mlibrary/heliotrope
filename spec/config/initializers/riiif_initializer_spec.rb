# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Riiif::Image do
  describe "configuration after a development reload" do
    it "configures the reloaded image class to use Fedora and the network cache" do
      reloaded_image = Class.new do
        class_attribute :file_resolver, :info_service
      end
      stub_const("Riiif::Image", reloaded_image)

      expect(Rails.application.config).to receive(:to_prepare).and_yield
      load Rails.root.join("config", "initializers", "riiif_initializer.rb")

      resolver = Riiif::Image.file_resolver
      expect(resolver).to be_a(Riiif::HttpFileResolver)
      expect(resolver.cache_path).to eq Settings.riiif_network_files_path

      allow(ActiveFedora::SolrService).to receive(:query).and_return(
        [{ "original_file_id_ssi" => "111111111/files/original", "height_is" => 600, "width_is" => 400 }]
      )
      expect(resolver.id_to_uri.call("111111111")).to eq ActiveFedora::Base.id_to_uri("111111111/files/original")
      expect(Riiif::Image.info_service.call("111111111", nil)).to eq(height: 600, width: 400)

      file = Riiif::File.new(Rails.root.join("spec", "fixtures", "world.png").to_s)
      allow(resolver).to receive(:find).with("111111111").and_return(file)
      expect(Riiif::Image.cache_key("111111111", {})).to end_with(Digest::MD5.file(file.path).to_s)
    end
  end

  describe "#file_resolver.id_to_uri" do
    context "with original_file_id_ssi indexed" do
      let(:fs1) do
        ::SolrDocument.new(id: '111111111',
                           has_model_ssim: ['FileSet'],
                           original_file_id_ssi: "111111111/files/c2ae57cc-bb27-4d43-af8a-aab28cf807ba/fcr:versions/version1")
      end

      before do
        ActiveFedora::SolrService.add(fs1.to_h)
        ActiveFedora::SolrService.commit
      end

      it "returns the file uri for download" do
        expect(Riiif::Image.file_resolver.id_to_uri.call("111111111")).to match "/rest/test/11/11/11/11/111111111/files/c2ae57cc-bb27-4d43-af8a-aab28cf807ba/fcr:versions/version1"
      end
    end

    context "if there's no original_file_id_ssi" do
      # Prior to around hyrax 2.5, the "original_file_id_ssi" field was not indexed.
      # See https://tools.lib.umich.edu/jira/browse/HELIO-3332?focusedCommentId=1019705&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-1019705
      # All pre Hyrax 2.5 image files on testing/staging/preview and production have now been reindexed
      # So we should never see that field missing, but on the very remote chance it is, we'll test the "sad" path.
      let(:fs1) do
        ::SolrDocument.new(id: '222222222',
                           has_model_ssim: ['FileSet'])
      end

      before do
        ActiveFedora::SolrService.add(fs1.to_h)
        ActiveFedora::SolrService.commit
      end

      it "returns nothing, with no errors" do
        expect(Riiif::Image.file_resolver.id_to_uri.call("222222222")).to eq ""
      end
    end

    context "with a missing/incorrect noid" do
      it "returns nothing, with no errors" do
        expect(Riiif::Image.file_resolver.id_to_uri.call("x9")).to eq ""
      end
    end
  end
end
