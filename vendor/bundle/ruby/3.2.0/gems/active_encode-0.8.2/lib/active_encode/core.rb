# frozen_string_literal: true
require 'active_support'
require 'active_encode/callbacks'

module ActiveEncode
  module Core
    extend ActiveSupport::Concern

    included do
      # Encode Identifier
      attr_accessor :id

      # Encode input
      # @return ActiveEncode::Input
      attr_accessor :input

      # Encode output(s)
      # @return Array[ActiveEncode::Output]
      attr_accessor :output

      # Encode options
      attr_accessor :options

      attr_accessor :current_operations
      attr_accessor :percent_complete
    end

    module ClassMethods
      def default_options(_input_url)
        {}
      end

      def create(input_url, options = {})
        object = new(input_url, options)
        object.create!
      end

      def find(id)
        raise ArgumentError, 'id cannot be nil' unless id
        encode = new(nil)
        encode.run_callbacks :find do
          encode.send(:merge!, engine_adapter.find(id))
        end
      end
    end

    def initialize(input_url, options = nil)
      @input = Input.new.tap { |input| input.url = input_url }
      @options = self.class.default_options(input_url).merge(Hash(options))
    end

    def create!
      run_callbacks :create do
        merge!(self.class.engine_adapter.create(input.url, options))
      end
    end

    def cancel!
      run_callbacks :cancel do
        merge!(self.class.engine_adapter.cancel(id))
      end
    end

    def reload
      run_callbacks :reload do
        merge!(self.class.engine_adapter.find(id))
      end
    end

    def created?
      !id.nil?
    end

    protected

      def merge!(encode)
        @id = encode.id
        @input = encode.input
        @output = encode.output
        @options = encode.options
        @state = encode.state
        @errors = encode.errors
        @created_at = encode.created_at
        @updated_at = encode.updated_at
        @current_operations = encode.current_operations
        @percent_complete = encode.percent_complete

        self
      end
  end
end
