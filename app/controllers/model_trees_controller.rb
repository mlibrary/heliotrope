# frozen_string_literal: true

class ModelTreesController < ApplicationController
  before_action :set_model_tree, only: %i[show]

  def show
  end

  def kind
    model_tree = ModelTree.from_noid(params[:id])
    model_tree.kind = params[:kind]
    model_tree.save
    redirect_to model_tree_path(params[:show_id] || params[:id]), notice: 'Kind was successfully set.'
  end

  def unkind
    model_tree = ModelTree.from_noid(params[:id])
    model_tree.kind = nil
    model_tree.save
    redirect_to model_tree_path(params[:show_id] || params[:id]), notice: 'Kind was successfully unset.'
  end

  def link
    ModelTreeService.new.link(params[:parent_id] || params[:id], params[:child_id])
    redirect_to model_tree_path(params[:show_id] || params[:id]), notice: 'Link was successfully created.'
  end

  def unlink
    ModelTreeService.new.unlink_parent(params[:id])
    redirect_to model_tree_path(params[:show_id] || params[:id]), notice: 'Link was successfully deleted.'
  end

  private

    def set_model_tree
      @entity = Sighrax.from_noid(params[:id])
      @press = Sighrax.press(@entity) # needed for boilerplate layout
      @hyrax_presenter = Sighrax.hyrax_presenter(@entity) # needed for breadcrumbs helper
      @model_tree = ModelTree.from_entity(@entity) # Rails convention
      @presenter = ModelTreePresenter.new(current_actor, @model_tree) # Heliotrope convention
    end
end
