# frozen_string_literal: true

module Hyrax
  # Generated form for Score
  class ScoreForm < Hyrax::Forms::WorkForm
    self.model_class = ::Score
    # self.terms += [:resource_type]
    self.terms -= %i[keyword related_url source based_near contributor subject language identifier]
    self.required_fields -= %i[keyword rights_statement]

    self.terms += %i[press octave_compass bass_bells_required bass_bells_omitted solo amplified_electronics
                     electronics_without_adjustment duet_or_ensemble musical_presentation recommended_for_students
                     composer_diversity appropriate_occasion composer_contact_information
                     year_of_composition number_of_movements premiere_status]

    self.required_fields += %i[title creator press octave_compass solo amplified_electronics musical_presentation]

    delegate :current_user, to: :current_ability

    def select_press
      press = Press.where(subdomain: Services.score_press).first
      Hash[press.name, press.subdomain]
    end

    def self.multiple?(field)
      if %i[title creator description].include? field.to_sym
        false
      else
        super
      end
    end

    def self.model_attributes(_nil)
      attrs = super
      attrs[:title] = Array(attrs[:title]) if attrs[:title]
      attrs[:description] = Array(attrs[:description]) if attrs[:description]
      attrs[:creator] = Array(attrs[:creator]) if attrs[:creator]
      attrs
    end

    def title
      super.first || ""
    end

    def creator
      super.first || ""
    end

    def description
      super.first || ""
    end

    #
    # These are methods for checkbox groups that include an "other" text input option
    #

    def amplifed_electronics_list
      ['No', 'Optional', 'Fixed Media', 'Live Processing']
    end

    def amplified_electronics
      @model.amplified_electronics
    end

    def other_amplified_electronic_value
      amplified_electronics.to_a - amplifed_electronics_list
    end

    def appropriate_occasion_list
      ['celebration', 'worship (Christian)', 'worship (non-Chirstian)', 'cultural diversity', 'memorial', 'social justice']
    end

    def appropriate_occasion
      @model.appropriate_occasion
    end

    def other_appropriate_occasion_value
      appropriate_occasion.to_a - appropriate_occasion_list
    end

    def music_rights_organization_list
      ['BMI', 'ASCAP', 'APRA', 'SABAM', 'SOCAN', 'KODA', 'GEMA', 'BUMA', 'RAO']
    end

    def music_rights_organization
      @model.music_rights_organization
    end

    def other_music_rights_organization
      music_rights_organization.to_a - music_rights_organization_list
    end
  end
end
