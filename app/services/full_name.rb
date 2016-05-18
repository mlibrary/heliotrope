class FullName
  def self.build(family_name, given_name)
    joining_comma = family_name.blank? || given_name.blank? ? '' : ', '
    family_name.to_s + joining_comma + given_name.to_s
  end
end
