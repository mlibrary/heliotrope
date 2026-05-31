# -*- encoding: utf-8 -*-
# frozen_string_literal: true
$:.unshift(File.expand_path("../ld", __FILE__))
require 'json'

module JSON
  ##
  # `JSON::Canonicalization` generates canonical JSON output from Ruby objects
  module Canonicalization
    autoload :VERSION,            'json/ld/version'
  end
end

class Object
  # Default canonicalization output for Ruby objects
  # @return [String]
  def to_json_c14n
    ::JSON.generate(self)
  end
end

class Array
  def to_json_c14n
    '[' + self.map(&:to_json_c14n).join(',') + ']'
  end
end

class Numeric
  def to_json_c14n
    raise RangeError if self.is_a?(Float) && (self.nan? || self.infinite?)
    return "0" if self.zero?
    num = self
    if num < 0
      num, sign = -num, '-'
    end
    native_rep = "%.15E" % num
    decimal, exponential = native_rep.split('E')
    exp_val = exponential.to_i
    exponential = exp_val > 0 ? ('+' + exp_val.to_s) : exp_val.to_s

    integral, fractional = decimal.split('.')
    fractional = fractional.sub(/0+$/, '')  # Remove trailing zeros

    if exp_val > 0 && exp_val < 21
      while exp_val > 0
        integral += fractional.to_s[0] || '0'
        fractional = fractional.to_s[1..-1]
        exp_val -= 1
      end
      exponential = nil
    elsif exp_val == 0
      exponential = nil
    elsif exp_val < 0 && exp_val > -7
      # Small numbers are shown as 0.etc with e-6 as lower limit
      fractional, integral, exponential = integral + fractional.to_s, '0', nil
      fractional = ("0" * (-exp_val - 1)) + fractional
    end

    fractional = nil if fractional.to_s.empty?
    sign.to_s + integral + (fractional ? ".#{fractional}" : '') + (exponential ? "e#{exponential}" : '')
  end
end

def encode_key(k)
  case k
  when String
    return k.encode(Encoding::UTF_16)
  end
  k
end

class Hash
  # Output JSON with keys sorted lexicographically
  # @return [String]
  def to_json_c14n
    "{" + self.
      keys.
      sort_by {|k| encode_key(k)}.
      map {|k| k.to_json_c14n + ':' + self[k].to_json_c14n}
      .join(',') +
    '}'
  end
end

class String
  # Output JSON with control characters escaped
  # @return [String]
  def to_json_c14n
    ::JSON.generate(self)
  end
end

class Symbol
  # Output JSON with control characters escaped
  # @return [String]
  def to_json_c14n
    ::JSON.generate(self)
  end
end
