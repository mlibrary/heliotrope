#!/usr/bin/env ruby
# frozen_string_literal: true

require 'httparty'

class Lackey
  include HTTParty
  format :json
  base_uri "localhost:3000/api"
  headers authorization: "Bearer #{ENV['HELIOTROPE_TOKEN']}",
          accept: "application/json, application/vnd.heliotrope.v1+json",
          content_type: "application/json"

  attr_reader :argv

  def initialize(argv)
    @argv = argv
  end

  def parse
    argv.each_with_index do |arg, idx|
      puts "arg[#{idx}] = #{arg}"
    end
    nil
  end

  def find_product(identifier:)
    response = self.class.get("/product", { query: { identifier: identifier } } )
    return response.parsed_response["id"] if response.success?
    nil
  rescue StandardError => e
    STDERR.puts e.message
    nil
  end

  def create_product(identifier:, purchase: "x")
    response = self.class.post("/products", { body: { product: { identifier: identifier, purchase: purchase } }.to_json } )
    return response.parsed_response["id"] if response.success?
    nil
  rescue StandardError => e
    STDERR.puts e.message
    nil
  end

  def find_or_create_product(identifier:)
    id = find_product(identifier: identifier)
    return id unless id.nil?
    create_product(identifier: identifier)
  end

  def delete_product(identifier:)
    id = find_product(identifier: identifier)
    return if id.nil?
    self.class.delete("/products/#{id}")
  rescue StandardError => e
    STDERR.puts e.message
    nil
  end

  def products
    self.class.get('/products').parsed_response
  end

  def product_lessees(product_identifier:)
    product_id = find_product(identifier: product_identifier)
    return [] if product_id.nil?
    response = self.class.get("/products/#{product_id}/lessees")
    return response.parsed_response if response.success?
    []
  rescue StandardError => e
    STDERR.puts e.message
    []
  end

  def find_lessee(identifier:)
    response = self.class.get("/lessee", { query: { identifier: identifier } } )
    return response.parsed_response["id"] if response.success?
    nil
  rescue StandardError => e
    STDERR.puts e.message
    nil
  end

  def create_lessee(identifier:)
    response = self.class.post("/lessees", { body: { lessee: { identifier: identifier }  }.to_json } )
    return response.parsed_response["id"] if response.success?
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
    self.class.delete("/lessees/#{id}")
  rescue StandardError => e
    STDERR.puts e.message
    nil
  end

  def lessees
    self.class.get('/lessees').parsed_response
  end

  def lessee_products(lessee_identifier:)
    lessee_id = find_lessee(identifier: lessee_identifier)
    return [] if lessee_id.nil?
    response = self.class.get("/lessees/#{lessee_id}/products")
    return response.parsed_response if response.success?
    []
  rescue StandardError => e
    STDERR.puts e.message
    []
  end

  def link(product_identifier:, lessee_identifier:)
    product_id = find_or_create_product(identifier: product_identifier)
    lessee_id = find_or_create_lessee(identifier: lessee_identifier)
    link_product_lessee(product_id: product_id, lessee_id: lessee_id)
  end

  def unlink(product_identifier:, lessee_identifier:)
    product_id = find_or_create_product(identifier: product_identifier)
    lessee_id = find_or_create_lessee(identifier: lessee_identifier)
    unlink_product_lessee(product_id: product_id, lessee_id: lessee_id)
  end

  private

    def link_product_lessee(product_id:, lessee_id:)
      response = self.class.put("/products/#{product_id}/lessees/#{lessee_id}")
      response.success?
    rescue StandardError => e
      STDERR.puts e.message
      false
    end

    def unlink_product_lessee(product_id:, lessee_id:)
      response = self.class.delete("/products/#{product_id}/lessees/#{lessee_id}")
      response.success?
    rescue StandardError => e
      STDERR.puts e.message
      false
    end
end

lackey = Lackey.new(ARGV)
lackey.parse
