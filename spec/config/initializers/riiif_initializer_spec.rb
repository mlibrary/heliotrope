# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Riiif::Image do
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
