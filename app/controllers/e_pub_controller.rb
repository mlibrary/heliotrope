# frozen_string_literal: true

require 'zip'

class EPubController < ApplicationController
  def show
    presenter = CurationConcerns::FileSetPresenter.new(SolrDocument.new(FileSet.find(params[:id]).to_solr), current_ability, request)
    if presenter.epub?
      @title = presenter.title
      @citable_link = presenter.citable_link
      @back_link = params[:subdomain].present? ? main_app.root_url + params[:subdomain] : main_app.monograph_catalog_url(presenter.monograph_id)
      render layout: false
    else
      render 'curation_concerns/base/unauthorized', status: :unauthorized
    end
  rescue Ldp::Gone # tombstone
    raise CanCan::AccessDenied
  end

  def file
    file_set = FileSet.find(params[:id])
    file = file_set.original_file unless file_set.nil?
    if file
      epub_file = params[:file] + '.' + params[:format]
      Zip::File.open_buffer(file.content) do |zip_file|
        entry = zip_file.get_entry(epub_file)
        if entry
          render plain: entry.get_input_stream.read, layout: false
        else
          head :ok
        end
      end
    else
      head :ok
    end
  rescue
    head :ok
  end
end
