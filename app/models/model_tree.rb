# frozen_string_literal: true

class ModelTree
  include ActiveModel::Model
  private_class_method :new

  attr_reader :noid
  attr_reader :entity

  delegate :kind?, :kind, :kind=, to: :data

  def self.from_noid(noid)
    new(noid)
  end

  def self.from_entity(entity)
    new(entity.noid, entity)
  end

  def ==(other)
    noid == other.noid
  end

  def id
    noid
  end

  def null?
    entity.is_a?(Sighrax::NullEntity)
  end

  def press
    @press ||= Sighrax.press(entity)
  end

  def parent?
    !parent.null?
  end

  def parent
    @parent ||= ModelTree.from_noid(ModelTreeEdge.find_by(child_noid: noid)&.parent_noid || Sighrax::Entity.null_entity.noid)
  end

  def children?
    children.present?
  end

  def children
    @children ||= ModelTreeEdge.where(parent_noid: noid).map { |edge| ModelTree.send(:new, edge.child_noid) }
  end

  def resource_type # rubocop:disable Rails/Delegate
    entity.resource_type
  end

  def resource_id
    noid
  end

  def resource_token
    resource_type.to_s + ':' + resource_id.to_s
  end

  def save
    save!
  rescue StandardError => e
    Rails.logger.error("ERROR: ModelTree.save raised #{e}")
    false
  end

  def save!
    ModelTreeService.new.set_model_tree_data(noid, data)
    true
  end

  private

    def initialize(noid, entity = Sighrax.from_noid(noid))
      @noid = noid
      @entity = entity
    end

    def data
      @data ||= ModelTreeData.from_noid(noid)
    end
end
