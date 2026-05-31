# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class GetPreview < DropboxApi::Endpoints::ContentDownload
    Method      = :post
    Path        = '/2/files/get_preview'
    ResultType  = DropboxApi::Metadata::File
    ErrorType   = DropboxApi::Errors::PreviewError

    # Get a preview for a file. Currently previews are only generated for the
    # files with the following extensions: .doc, .docx, .docm, .ppt, .pps,
    # .ppsx, .ppsm, .pptx, .pptm, .xls, .xlsx, .xlsm, .rtf
    #
    # @param path [String] The path of the file to preview.
    add_endpoint :get_preview do |path, &block|
      perform_request({path: path}, &block)
    end
  end
end
