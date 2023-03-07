# frozen_string_literal: true

class StaticMetadataController < ApplicationController
  # This is the result of some odd compromises
  # It's just a map of the file system really
  # see HELIO-4408
  def index
    # /products/:group_key/:file_type/:file
    group_key = params[:group_key]
    file_type = params[:file_type]

    @links = {}

    if group_key.nil? && file_type.nil?
      Dir.glob(root_dir + "*").each do |dir|
        location = Pathname.new(dir).basename.to_s
        @links[location] = "/products/" + location
      end
    end

    if group_key.present? && file_type.nil?
      Dir.glob(root_dir + group_key + "*").each do |dir|
        location = Pathname.new(dir).basename.to_s
        @links[location] = "/products/#{group_key}/" + location
      end
    end

    if group_key.present? && file_type.present?
      Dir.glob(root_dir + group_key + file_type + "*").sort.reverse_each do |dir|
        location = Pathname.new(dir).basename.to_s
        @links[location] = "/products/#{group_key}/#{file_type}/" + location
      end
    end
  end

  private

    def root_dir
      Rails.root.join("public", "products")
    end
end
