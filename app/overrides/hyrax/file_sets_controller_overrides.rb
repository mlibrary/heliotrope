# frozen_string_literal: true

Hyrax::FileSetsController.class_eval do
  prepend(FileSetsControllerBehavior = Module.new do
    Hyrax::FileSetsController.form_class = ::Heliotrope::FileSetEditForm

    def show
      # local heliotrope changes
      (redirect_to Rails.application.routes.url_helpers.monograph_catalog_path(presenter&.parent&.id)) && return if bounce_from_representatives?

      redirect_to redirect_link, status: :moved_permanently if redirect_link.present?
      if presenter.multimedia?
        CounterService.from(self, presenter).count(request: 1)
      else
        CounterService.from(self, presenter).count
      end

      stats_graph_service = StatsGraphService.new(params[:id], presenter.date_uploaded)
      @stats_graph_data = stats_graph_service.pageviews_over_time_graph_data
      @pageviews = stats_graph_service.pageviews

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

    def bounce_from_representatives?
      # non-editors and search engines shouldn't see show pages for covers or "representative" FileSets
      featured_rep = FeaturedRepresentative.where(file_set_id: params[:id]).first
      !(can? :edit, params[:id]) && (featured_rep.present? || [presenter&.parent&.representative_id, presenter&.parent&.thumbnail_id].include?(params[:id]))
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

    # this is provided so that implementing application can override this behavior and map params to different attributes
    def update_metadata
      file_attributes = form_class.model_attributes(attributes)
      if /^interactive map$/i.match?(file_attributes['resource_type']&.first)
        UnpackJob.perform_later(params[:id], 'interactive_map') unless Sighrax.from_noid(params[:id]).is_a?(Sighrax::InteractiveMap)
      end
      actor.update_metadata(file_attributes)
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
          process_extra_json_properties
          update_metadata
        end
      end
    end

    # See HELIO-2912. We're trying a thing here...
    # Special properties for certain flavors of FileSet are added as json
    def process_extra_json_properties
      props = {}
      props[:score_version] = params[:file_set].delete(:score_version) if params[:file_set][:score_version].present?
      params[:file_set][:extra_json_properties] = props.to_json
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
