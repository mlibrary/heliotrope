# frozen_string_literal: true

class ModelTreeData
  KINDS = %w[aboutware captions cover database descriptions epub mobi pdf_ebook peer_review related reviews transcript webgl].freeze
  private_class_method :new

  def self.from_noid(noid)
    vertex = ModelTreeVertex.find_by(noid: noid)
    json = if vertex.present? && vertex.data.present?
             vertex.data
           else
             { data: {} }.to_json
           end
    from_json(json)
  end

  def self.from_json(json)
    from_hash(JSON.parse(json)["data"])
  end

  def self.from_hash(hash)
    new(hash)
  end

  def ==(other)
    @data == other.data
  end

  def kind?
    kind.present?
  end

  def kind
    @data["kind"]
  end

  def kind=(value)
    @data["kind"] = value
  end

  protected

    attr_reader :data

  private

    def initialize(hash)
      @data = hash
    end
end
