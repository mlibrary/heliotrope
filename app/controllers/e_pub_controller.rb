# frozen_string_literal: true

require 'zip'

class EPubController < ApplicationController
  def show
    file_set_doc = ActiveFedora::SolrService.query("{!terms f=id}#{params[:id]}", row: 1).first
    mime_type = file_set_doc['mime_type_ssi'] unless file_set_doc.nil?
    epub_zip = mime_type.include? 'application/epub+zip' unless mime_type.nil?
    if epub_zip
      render layout: false
    else
      render 'curation_concerns/base/unauthorized', status: :unauthorized
    end
  end

  def file
    file_set = FileSet.find(params[:id])
    file = file_set.original_file unless file_set.nil?
    if file
      epub_file = params[:file] + '.' + params[:format]
      begin
        Zip::File.open_buffer(file.content) do |zip_file|
          entry = zip_file.get_entry(epub_file)
          if entry
            render plain: entry.get_input_stream.read, layout: false
          else
            head :ok
          end
        end
      rescue
        head :ok
      end
    else
      head :ok
    end
  end
end
