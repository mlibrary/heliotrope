# frozen_string_literal: true

class ManifestPresenter < ApplicationPresenter
  attr_reader :current_user

  def initialize(current_user, manifest)
    super(current_user)
    @manifest = manifest
  end
  delegate :monograph_id, :id, :table_headers, :table_rows, :persisted?, :filename, to: :@manifest
end
