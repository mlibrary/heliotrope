module BCP47
  class Subtag
    attr_reader :code

    def initialize(code, options={})
      @code = code
    end

    def ==(object)
      code == object.code
    end

    def name
      I18n.t(code, scope: i18n_scope)
    end

    def full_name
      "#{code} - #{name}"
    end

    def self.all
      YAML.load_file(self::DEFINITIONS_FILE).map do |code, options|
        symbolized_options = {}
        options.keys.each { |key| symbolized_options[key.to_sym] = options[key] } if options
        new(code, symbolized_options)
      end
    end

    def self.find(code)
      all.find {|subtag| subtag.code == code }
    end

    def self.default
      find(self::DEFAULT_CODE)
    end

    def self.codes
      all.map(&:code)
    end

  private
    def i18n_scope
      %w(vendor bcp47).join('.')
    end
  end
end
