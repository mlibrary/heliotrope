# frozen_string_literal: true

require "ipaddr"

# looks up institution ID(s) by IP address
class Keycard::InstitutionFinder
  IDENTITY_ATTRS = %i[dlpsInstitutionId].freeze

  INST_QUERY = <<~SQL
      SELECT inst FROM aa_network WHERE
              ? >= dlpsAddressStart
          AND ? <= dlpsAddressEnd
          AND dlpsAccessSwitch = 'allow'
          AND dlpsDeleted = 'f'
          AND inst is not null
    AND inst NOT IN
        ( SELECT inst FROM aa_network WHERE
          ? >= dlpsAddressStart
          AND ? <= dlpsAddressEnd
          AND dlpsAccessSwitch = 'deny'
          AND dlpsDeleted = 'f' )
  SQL

  def initialize(db: Keycard::DB.db)
    @db = db
    @stmt = @db[INST_QUERY, *[:$client_ip] * 4].prepare(:select, :unused)
  end

  def identity_keys
    IDENTITY_ATTRS
  end

  def attributes_for(request)
    return {} unless (numeric_ip = numeric_ip(request.client_ip))

    insts = insts_for_ip(numeric_ip)

    if !insts.empty?
      {dlpsInstitutionId: insts}
    else
      {}
    end
  end

  private

  attr_reader :stmt

  def insts_for_ip(numeric_ip)
    stmt.call(client_ip: numeric_ip).map { |row| row[:inst] }
  end

  def numeric_ip(dotted_ip)
    return unless dotted_ip

    begin
      IPAddr.new(dotted_ip).to_i
    rescue IPAddr::InvalidAddressError
      nil
    end
  end
end
