class BCP47::Language < BCP47::Subtag
  DEFINITIONS_FILE          = "#{File.dirname(__FILE__)}/../../data/iso-639-1.yml"
  DEFAULT_PLURAL_RULE_NAMES = %w(one other)
  DEFAULT_DIRECTION         = 'ltr'
  DEFAULT_CODE              = 'en'
  PLURAL_RULE_NAMES         = %w(zero one two few many other)

  attr_reader :plural_rule_names, :direction

  def initialize(code, options={})
    @plural_rule_names = options[:plural_rule_names] || DEFAULT_PLURAL_RULE_NAMES
    @direction         = options[:direction]         || DEFAULT_DIRECTION
    super(code, options)
  end

  def self.identify(full_code)
    segments = full_code.split('-')
    segments.first =~ /^([a-z]{2})$/ ? find($1) : nil
  end

private
  def i18n_scope
    super << ".languages"
  end
end
