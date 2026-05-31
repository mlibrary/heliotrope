require 'spec_helper'

describe "deprecated module methods" do
  module DeprecatedModule
    extend Deprecation

    self.deprecation_behavior = :raise

    self.deprecation_horizon = 'release 0.1'
    def a

    end

    deprecation_deprecate :a
  end

  module DeprecatedModuleLater
    extend Deprecation

    self.deprecation_behavior = :raise

    self.deprecation_horizon = 'release 0.2'
    def b

    end

    deprecation_deprecate :b
  end
  class DeprecationModuleTest
    include DeprecatedModule
    include DeprecatedModuleLater
  end
  subject { DeprecationModuleTest.new}

  describe "a" do
    it "should be deprecated" do
      expect { subject.a }.to raise_error /a is deprecated/
    end
  end
  describe "b" do
    it "should be deprecated in release 0.2" do
      expect { subject.b }.to raise_error /b is deprecated and will be removed from release 0.2/
    end
  end
end
