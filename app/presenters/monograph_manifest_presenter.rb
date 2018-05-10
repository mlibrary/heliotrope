# frozen_string_literal: true

class MonographManifestPresenter < ApplicationPresenter
  attr_reader :current_user

  def initialize(current_user, monograph_manifest)
    super(current_user)
    @monograph_manifest = monograph_manifest
  end

  delegate :id, to: :@monograph_manifest

  def explicit
    @explicit ||= ManifestPresenter.new(current_user, @monograph_manifest.explicit)
  end

  def implicit
    @implicit ||= ManifestPresenter.new(current_user, @monograph_manifest.implicit)
  end

  def equivalent?
    @monograph_manifest.implicit == @monograph_manifest.explicit
  end
end
