require 'rspec/matchers' # @see https://rubygems.org/gems/rspec
require_relative 'support/extensions'

RSpec::Matchers.define :produce_yamlld do |expected, logger|
  match do |actual|
    actual = YAML_LD::Representation.load(actual, aliases: true) if actual.is_a?(String)
    expected = YAML_LD::Representation.load(expected, aliases: true) if expected.is_a?(String)
    expect(actual).to be_equivalent_structure expected
  end

  failure_message do |actual|
    "Expected: #{expected.is_a?(String) ? expected : expected.to_yaml rescue 'malformed structure'}\n" +
    "Actual  : #{actual.is_a?(String) ? actual : actual.to_yaml rescue 'malformed structure'}\n" +
    "\nDebug:\n#{logger}"
  end

  failure_message_when_negated do |actual|
    "Expected not to produce the following:\n" + 
    "Actual  : #{actual.is_a?(String) ? actual : actual.to_yaml rescue 'malformed structure'}\n" +
    "\nDebug:\n#{logger}"
  end
end
