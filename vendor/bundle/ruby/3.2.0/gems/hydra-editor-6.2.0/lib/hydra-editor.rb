require 'hydra_editor/engine'

module HydraEditor
  class InvalidType < RuntimeError; end

  extend ActiveSupport::Autoload

  autoload :ControllerResource

  def self.models=(val)
    @models = val
  end

  def self.models
    @models ||= []
  end

  def self.valid_model?(type)
    models.include? type
  end
end
