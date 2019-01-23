# frozen_string_literal: true

Hyrax::FileSetsController.class_eval do
  prepend(FileSetsControllerBehavior = Module.new do
    Hyrax::FileSetsController.form_class = ::Heliotrope::FileSetEditForm

    def show
      # local heliotrope change
      redirect_to redirect_link, status: :moved_permanently if redirect_link.present?
      if presenter.multimedia?
        CounterService.from(self, presenter).count(request: 1)
      else
        CounterService.from(self, presenter).count
      end
      respond_to do |wants|
        wants.html { presenter }
        wants.json { presenter }
        additional_response_formats(wants)
      end
    end

    def destroy
      FeaturedRepresentative.where(file_set_id: params[:id]).first&.destroy
      super
    end

    def redirect_link
      # there may be a use case in future for external redirection, but for right now it's just FileSet to FileSet
      link = file_set_doc['redirect_to_ssim']&.first
      return nil if link.blank?
      if link&.length == 9 && ::FileSet.where(id: link).present?
        Rails.application.routes.url_helpers.hyrax_file_set_path(link)
      else
        '/'
      end
    end

    def file_set_doc
      ActiveFedora::SolrService.query("{!terms f=id}#{params[:id]}", rows: 1)&.first || {}
    end

    def attempt_update
      if wants_to_revert?
        actor.revert_content(params[:revision])
      elsif params.key?(:user_thumbnail)
        change_thumbnail
      elsif params.key?(:file_set)
        if params[:file_set].key?(:files)
          actor.update_content(params[:file_set][:files].first)
        else
          update_metadata
        end
      end
    end

    def change_thumbnail
      if params[:user_thumbnail].key?(:custom_thumbnail)
        dest = Hyrax::DerivativePath.derivative_path_for_reference(params[:id], 'thumbnail')
        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.cp(params[:user_thumbnail][:custom_thumbnail].path, dest)
      end
      if params[:user_thumbnail].key?(:use_default)
        if params[:user_thumbnail][:use_default] == '1'
          ActiveFedora::SolrService.add(@file_set.to_solr.merge(thumbnail_path_ss: ActionController::Base.helpers.image_path('default.png')), softCommit: true)
        else
          ActiveFedora::SolrService.add(@file_set.to_solr.merge(thumbnail_path_ss: Hyrax::Engine.routes.url_helpers.download_path(@file_set.id, file: 'thumbnail')), softCommit: true)
        end
      end
      # neither FileUtils nor SolrService return useful values, so both a FileUtils.compare_file and Solr query would...
      # be necessary to check for overall success. Not going to bother with that for now, returning `true`.
      true
    end

    def reindex
      UpdateIndexJob.perform_later(params[:id])
      redirect_to [main_app, @file_set], notice: "Reindexing Job Scheduled"
    end
  end)
end
