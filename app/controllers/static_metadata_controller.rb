# frozen_string_literal: true

class StaticMetadataController < ApplicationController
  # This is the result of some odd compromises
  # It's just a map of the file system under public/products
  # see HELIO-4408
  def index
    # /products/:group_key/:file_type/:file
    group_key = params[:group_key]
    file_type = params[:file_type]

    @links = {}

    # Something interesting happens sometimes in production for
    # GET /products
    # It looks like apache (or something?) changes that into
    # GET /products/index.html
    # which then comes through rails as: param[:group_key] = "index"
    # It doesn't always happen, oddily, but we need to deal with it.
    if (group_key.nil? || group_key == "index") && file_type.nil?
      Dir.glob(root_dir + "*").each do |dir|
        location = Pathname.new(dir).basename.to_s
        @links[location] = "/products/" + location
      end
    end

    if group_key.present? && (file_type.nil? || file_type == "index")
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
