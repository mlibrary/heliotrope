# frozen_string_literal: true

module ExternalResourceHelper
  def glyphicon_type(resource_type)
    return 'glyphicon glyphicon-file' if resource_type.blank?
    case resource_type.first.downcase
    when 'text'
      'glyphicon glyphicon-file'
    when 'image'
      'glyphicon glyphicon-picture'
    when 'video'
      'glyphicon glyphicon-film'
    when 'audio'
      'glyphicon glyphicon-volume-up'
    else
      'glyphicon glyphicon-file'
    end
  end
end
