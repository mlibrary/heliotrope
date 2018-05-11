# frozen_string_literal: true

# Monograph Manifest model backed by Manifest model.
#
# Instance Methods
#   implicit - manifest of monograph stored in Fedora
#   explicit - manifest of monograph stored on filesystem (a.k.a. csv)
#
class MonographManifest
  include ActiveModel::Model

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def implicit
    @implicit ||= Manifest.from_monograph(id)
  end

  def explicit
    @explicit ||= Manifest.from_monograph_manifest(id)
  end

  def persisted?
    true
  end
end
