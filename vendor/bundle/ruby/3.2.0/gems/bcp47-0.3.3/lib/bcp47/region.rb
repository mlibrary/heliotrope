class BCP47::Region < BCP47::Subtag
  DEFINITIONS_FILE = "#{File.dirname(__FILE__)}/../../data/iso-3166-1.yml"

  def self.identify(full_code)
    full_code =~ /[-_]([A-Z]{2})$/ ? find($1) : nil
  end

private
  def i18n_scope
    super << ".regions"
  end
end
