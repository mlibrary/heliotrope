# frozen_string_literal: true

# This copyright notice applies to this file only.
# The original source was taken from:
# https://github.com/basecamp/deep_hash_transform
#
# Copyright (c) 2005-2014 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Ettin

  # Contains the logic for deep transformation of hash keys
  module DeepTransform
    # Returns a new hash with all keys converted by the block operation.
    # This includes the keys from the root hash and from all
    # nested hashes.
    #
    #  hash = { person: { name: 'Rob', age: '28' } }
    #
    #  hash.deep_transform_keys{ |key| key.to_s.upcase }
    #  # => {"PERSON"=>{"NAME"=>"Rob", "AGE"=>"28"}}
    unless method_defined?(:deep_transform_keys)
      def deep_transform_keys(&block)
        result = {}
        each do |key, value|
          result[yield(key)] = value.is_a?(Hash) ? value.deep_transform_keys(&block) : value
        end
        result
      end
    end

    # Destructively convert all keys by using the block operation.
    # This includes the keys from the root hash and from all
    # nested hashes.
    unless method_defined?(:deep_transform_keys!)
      def deep_transform_keys!(&block)
        keys.each do |key|
          value = delete(key)
          self[yield(key)] = value.is_a?(Hash) ? value.deep_transform_keys!(&block) : value
        end
        self
      end
    end
  end
end

unless {}.respond_to?(:deep_transform_keys)
  Hash.include Ettin::DeepTransform
end
