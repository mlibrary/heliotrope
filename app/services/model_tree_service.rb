# frozen_string_literal: true

class ModelTreeService
  def get_model_tree_data(noid, restore = false)
    vertex = ModelTreeVertex.find_by(noid: noid)
    raise("ModelTreeVertex #{noid} NOT found!") if vertex.blank?

    if restore
      vertex.data = active_fedora_get_model_metadata_json(noid)
      vertex.save!
    end

    ModelTreeData.from_json(vertex.data)
  end

  def set_model_tree_data(noid, model_tree_data = nil)
    vertex = ModelTreeVertex.find_by(noid: noid)
    raise("ModelTreeVertex #{noid} NOT found!") if vertex.blank?

    json = nil
    if model_tree_data.present?
      raise("ModelTreeData invalid!") unless model_tree_data.is_a?(ModelTreeData)
      json = model_tree_data.to_json
    end

    active_fedora_set_model_metadata_json(noid, json)

    vertex.data = json
    vertex.save!
  end

  def link(parent_noid, child_noid)
    edge = ModelTreeEdge.find_by(parent_noid: parent_noid, child_noid: child_noid)
    return true if edge.present?

    child_has_parent = ModelTreeEdge.find_by(child_noid: child_noid).present?
    return false if child_has_parent

    active_fedora_link(parent_noid, child_noid)

    _edge = ModelTreeEdge.create(parent_noid: parent_noid, child_noid: child_noid)
    _parent = ModelTreeVertex.find_or_create_by(noid: parent_noid)
    _child = ModelTreeVertex.find_or_create_by(noid: child_noid)

    true
  end

  def unlink(noid)
    unlink_parent(noid)
    unlink_children(noid)
    true
  end

  def unlink_parent(child_noid)
    edge = ModelTreeEdge.find_by(child_noid: child_noid)
    return true if edge.blank?

    parent = ModelTreeVertex.find_by(noid: edge.parent_noid)
    child = ModelTreeVertex.find_by(noid: edge.child_noid)

    active_fedora_unlink_parent(child_noid)

    edge.destroy

    parent_has_child = ModelTreeEdge.where(parent_noid: parent&.noid).present?
    parent_is_child = ModelTreeEdge.where(child_noid: parent&.noid).present?
    parent&.destroy unless parent_has_child || parent_is_child

    child_is_parent = ModelTreeEdge.where(parent_noid: child&.noid).present?
    child&.destroy unless child_is_parent

    true
  end

  def unlink_children(parent_noid)
    edges = ModelTreeEdge.where(parent_noid: parent_noid)
    edges.each do |edge|
      unlink_parent(edge.child_noid)
    end
    true
  end

  def select_parent_options(noid)
    return [] if ModelTreeEdge.find_by(child_noid: noid).present?

    root_entity = root_entity(noid)
    return [] if root_entity.noid == noid

    exclusions = ModelTreeEdge.where(parent_noid: noid).pluck(:child_noid).prepend(noid)

    root_entity.children_noids.prepend(root_entity.noid).reject { |n| exclusions.include?(n) }
  end

  def select_child_options(noid)
    root_entity = root_entity(noid)
    return [] if root_entity.is_a?(Sighrax::NullEntity)

    exclusions = ModelTreeEdge.pluck(:child_noid).prepend(noid)
    parent_noid = ModelTreeEdge.find_by(child_noid: noid)&.parent_noid
    exclusions = exclusions.prepend(parent_noid) if parent_noid.present?

    root_entity.children_noids.reject { |n| exclusions.include?(n) }
  end

  private

    def active_fedora_get_model_metadata_json(noid)
      base = ActiveFedora::Base.find(noid)
      base.model_metadata_json
    end

    def active_fedora_set_model_metadata_json(noid, json = nil)
      base = ActiveFedora::Base.find(noid)
      base.model_metadata_json = json
      base.save!
    end

    def root_entity(noid)
      root_entity = Sighrax.from_noid(noid)
      until root_entity.parent.is_a?(Sighrax::NullEntity) do
        root_entity = root_entity.parent
      end
      root_entity
    end

    def active_fedora_link(parent_noid, child_noid)
      parent = ActiveFedora::Base.find(parent_noid)
      raise("ActiveFedora::Base #{noid} NOT found!") if parent.blank?
      child = ActiveFedora::Base.find(child_noid)
      raise("ActiveFedora::Base #{noid} NOT found!") if child.blank?
      child.model_parent_noid = parent_noid
      child.save!
    end

    def active_fedora_unlink_parent(child_noid)
      child = ActiveFedora::Base.find(child_noid)
      raise("ActiveFedora::Base #{noid} NOT found!") if child.blank?
      child.model_parent_noid = nil
      child.save!
    end
end
