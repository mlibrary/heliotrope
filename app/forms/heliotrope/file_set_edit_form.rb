# frozen_string_literal: true

module Heliotrope
  class FileSetEditForm < Hyrax::Forms::FileSetEditForm
    # In hyrax this seems to be used for FileSetsController.params.require(:file_set).permit
    # If removed you get the "Umpermitted Parameters" error...

    self.terms += %i[creator contributor resource_type caption alt_text copyright_holder
                     description content_type date_created keywords
                     language section_title license
                     copyright_status rights_granted
                     exclusive_to_platform permissions_expiration_date
                     allow_display_after_expiration allow_download_after_expiration
                     sort_date allow_download allow_hi_res credit_line
                     holding_contact external_resource_url doi hdl
                     display_date transcript translation redirect_to]

    # Per HELIO-2912, we dump json into this:
    self.terms += %i[extra_json_properties]
    # These are "temporary" and have to do with flavor of FileSet
    # They are turned into json then removed from params in the controller override
    self.terms += %i[score_version]

    # RE: below methods, see https://samvera.github.io/customize-metadata-other-customizations.html
    # TODO: copy this to fix up some other Hyrax::BasicMetadata fields on FileSets which are undesirably multi-valued
    def self.multiple?(field)
      if %i[license].include? field.to_sym
        false
      else
        super
      end
    end

    def self.model_attributes(_nil)
      attrs = super
      attrs[:license] = Array(attrs[:license]) if attrs[:license]
      attrs
    end

    def license
      super.first || ""
    end
  end
end
