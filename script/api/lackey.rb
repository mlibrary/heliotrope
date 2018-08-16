#!/usr/bin/env ruby
# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'json'

class Lackey
  def find_product(identifier:)
    response = connection.get("product", { identifier: identifier })
    return response.body["id"] if response.success?
    nil
  rescue StandardError => e
    STDERR.puts e.message
    nil
  end

  def create_product(identifier:, name:, purchase: "x")
    response = connection.post("products", { product: { identifier: identifier, name: name, purchase: purchase } }.to_json)
    return response.body["id"] if response.success?
    nil
  rescue StandardError => e
    STDERR.puts e.message
    nil
  end

  def find_or_create_product(identifier:, name:)
    id = find_product(identifier: identifier)
    return id unless id.nil?
    create_product(identifier: identifier, name: name)
  end

  def delete_product(identifier:)
    id = find_product(identifier: identifier)
    return if id.nil?
    connection.delete("products/#{id}")
  rescue StandardError => e
    STDERR.puts e.message
    nil
  end

  def products
    response = connection.get('products')
    return response.body if response.success?
    []
  end

  def product_lessees(product_identifier:)
    product_id = find_product(identifier: product_identifier)
    return [] if product_id.nil?
    response = connection.get("products/#{product_id}/lessees")
    return response.body if response.success?
    []
  rescue StandardError => e
    STDERR.puts e.message
    []
  end

  def find_lessee(identifier:)
    response = connection.get("lessee", { identifier: identifier })
    return response.body["id"] if response.success?
    nil
  rescue StandardError => e
    STDERR.puts e.message
    nil
  end

  def create_lessee(identifier:)
    response = connection.post("lessees", { lessee: { identifier: identifier } }.to_json)
    return response.body["id"] if response.success?
    nil
  rescue StandardError => e
    STDERR.puts e.message
    nil
  end

  def find_or_create_lessee(identifier:)
    id = find_lessee(identifier: identifier)
    return id unless id.nil?
    create_lessee(identifier: identifier)
  end

  def delete_lessee(identifier:)
    id = find_lessee(identifier: identifier)
    return if id.nil?
    connection.delete("lessees/#{id}")
  rescue StandardError => e
    STDERR.puts e.message
    nil
  end

  def lessees
    response = connection.get('lessees')
    return response.body if response.success?
    []
  end

  def lessee_products(lessee_identifier:)
    lessee_id = find_lessee(identifier: lessee_identifier)
    return [] if lessee_id.nil?
    response = connection.get("lessees/#{lessee_id}/products")
    return response.body if response.success?
    []
  rescue StandardError => e
    STDERR.puts e.message
    []
  end

  def link(product_identifier:, product_name:, lessee_identifier:)
    product_id = find_or_create_product(identifier: product_identifier, name: product_name)
    lessee_id = find_or_create_lessee(identifier: lessee_identifier)
    link_product_lessee(product_id: product_id, lessee_id: lessee_id)
  end

  def unlink(product_identifier:, product_name:, lessee_identifier:)
    product_id = find_or_create_product(identifier: product_identifier, name: product_name)
    lessee_id = find_or_create_lessee(identifier: lessee_identifier)
    unlink_product_lessee(product_id: product_id, lessee_id: lessee_id)
  end

  private
    def connection
      @connection ||= Faraday.new("http://localhost:3000/api") do |conn|
        conn.headers = {
            authorization: "Bearer #{ENV['HELIOTROPE_TOKEN']}",
            accept: "application/json, application/vnd.heliotrope.v1+json",
            content_type: "application/json"
        }
        conn.request :json
        conn.response :json, :content_type => /\bjson$/
        conn.adapter Faraday.default_adapter
      end
    end

    def link_product_lessee(product_id:, lessee_id:)
      response = connection.put("products/#{product_id}/lessees/#{lessee_id}")
      response.success?
    rescue StandardError => e
      STDERR.puts e.message
      false
    end

    def unlink_product_lessee(product_id:, lessee_id:)
      response = connection.delete("products/#{product_id}/lessees/#{lessee_id}")
      response.success?
    rescue StandardError => e
      STDERR.puts e.message
      false
    end
end
