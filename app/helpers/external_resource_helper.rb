# frozen_string_literal: true

module ExternalResourceHelper
  def glyphicon_type(resource_type)
    case resource_type.downcase
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
