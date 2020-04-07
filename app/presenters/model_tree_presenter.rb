# frozen_string_literal: true

class ModelTreePresenter < ApplicationPresenter
  attr_reader :model_tree

  delegate :id, :noid, :entity, :press, :kind?, :kind, :parent?, :children?, to: :model_tree

  def initialize(current_user, model_tree)
    super(current_user)
    @model_tree = model_tree
  end

  def display_name
    entity.title
  end

  def parent
    @parent ||= ModelTreePresenter.new(current_user, model_tree.parent)
  end

  def children
    @children ||= model_tree.children.map { |child| ModelTreePresenter.new(current_user, child) }
  end

  def kind_display
    I18n.t("model_tree_data.kind.#{kind}")
  end

  def kind_options?
    kind_options.present?
  end

  def kind_options
    @kind_options ||= ModelTreeData::KINDS.map { |k| [I18n.t("model_tree_data.kind.#{k}"), k] }
  end

  def parent_options?
    parent_options.present?
  end

  def parent_options
    @parent_options ||= ModelTreeService.new.select_parent_options(noid).map { |n| [Sighrax.from_noid(n).title, n] }
  end

  def child_options?
    child_options.present?
  end

  def child_options
    @child_options ||= ModelTreeService.new.select_child_options(noid).map { |n| [Sighrax.from_noid(n).title, n] }
  end
end
