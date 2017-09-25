# frozen_string_literal: true

module Valid
  def self.noid?(id)
    return false if id.nil?
    return false if id.blank?
    return false unless id.is_a?(String)
    return false if (id =~ /^[[:alnum:]]{9}$/).nil?
    true
  end
end
