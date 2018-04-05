# frozen_string_literal: true

class Token
  include ActiveModel::Model

  attr_reader :header, :payload, :signature

  def initialize(jwt)
    parts = jwt&.split('.') || []
    @header = parts[0]
    @payload = parts[1]
    @signature = parts[2]
  end

  def id
    @header + '.' + @payload + '.' + @signature
  end
end
