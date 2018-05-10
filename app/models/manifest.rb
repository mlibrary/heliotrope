# frozen_string_literal: true

require_dependency 'export'
require_dependency 'import'

# WARNING! DO NOT USE OUT OF CONTEXT!!!
#
# Specialized implementation model to be used only by MonographManifest model.
#
# Class factory methods:
#   from_monograph - manifest of monograph stored in Fedora
#   from_monograph_manifest - manifest of monograph stored on filesystem (a.k.a. Carrierwave)
#
# Instance methods:
#   create - upload csv file using Carrierwave
#   destroy - rm csv file
#   filename - csv filename with extension if csv file exists?
#   persisted? - csv file exists?
#   == - returns CSV self.table_rows == other.table_rows
#
# NOTE: #create is dependent on Carrierwave and was not tested.
#
# WARNING! DO NOT USE OUT OF CONTEXT!!!
class Manifest
  include ActiveModel::Model
  extend CarrierWave::Mount

  attr_reader :monograph_id
  alias_attribute :id, :monograph_id

  attr_accessor :csv
  # attr_accessor :csv, :remote_csv_url
  mount_uploader :csv, ManifestUploader # Tells rails to use this uploader for this model.

  # validates_presence_of :csv

  # extend CarrierWave::Validations::ActiveModel::HelperMethods
  # validates_integrity_of :csv
  # validates_processing_of :csv

  # en:
  #   errors:
  #     messages:
  #       carrierwave_processing_error: failed to be processed
  #       carrierwave_integrity_error: is not an allowed file type

  attr_reader :table_headers
  attr_accessor :table_rows

  def initialize(monograph_id, csv = nil)
    @monograph_id = monograph_id
    @csv = csv
    @table_headers = []
    @table_rows = []
  end

  def self.from_monograph(monograph_id)
    manifest = new(monograph_id)
    monograph = Monograph.find(monograph_id) if monograph_id.present?
    return manifest if monograph.blank?
    exporter = Export::Exporter.new(monograph_id)
    attributes = Import::CSVParser.new(nil).attributes(exporter.export)
    metadata = attributes.deep_dup
    metadata.delete('files')
    metadata.delete('files_metadata')
    metadata.delete('row_errors')
    manifest.table_rows << [metadata['id'], '://:MONOGRAPH://:', attributes['title']&.first, metadata]
    files = attributes['files']
    files_metadata = attributes['files_metadata']
    files.each.with_index do |file, index|
      manifest.table_rows << [files_metadata[index]['id'], file, files_metadata[index]['title']&.first, files_metadata[index]]
    end
    manifest
  end

  def self.from_monograph_manifest(monograph_id)
    manifest = new(monograph_id)
    monograph = Monograph.find(monograph_id) if monograph_id.present?
    return manifest if monograph.blank?
    return manifest unless manifest.persisted?
    importer = Import::CSVParser.new(File.join(manifest.path, manifest.filename))
    attributes = importer.attributes
    metadata = attributes.deep_dup
    metadata.delete('files')
    metadata.delete('files_metadata')
    metadata.delete('row_errors')
    manifest.table_rows << [metadata['id'], '://:MONOGRAPH://:', attributes['title']&.first, metadata]
    files = attributes['files']
    files_metadata = attributes['files_metadata']
    files.each.with_index do |file, index|
      manifest.table_rows << [files_metadata[index]['id'], file, files_metadata[index]['title']&.first, files_metadata[index]]
    end
    manifest
  end

  def create(current_user)
    return false unless Valid.noid?(@monograph_id)
    return false if @csv.blank?
    destroy(current_user)
    csv.cache!(content_type: @csv.content_type, filename: @csv.original_filename, tempfile: @csv.tempfile)
    store_csv!
    FileUtils.rm_rf(csv.cache_dir.to_s) if Dir.exist?(csv.cache_dir.to_s)
    true
  end

  def destroy(_current_user)
    FileUtils.rm_rf(path) if Dir.exist?(path)
  end

  def persisted?
    filename.present?
  end

  def path
    csv.store_dir.to_s
  end

  def filename
    return nil unless Dir.exist?(path)
    Dir.entries(path).drop(2).first
  end

  def ==(other)
    table_rows == other.table_rows
  end
end
