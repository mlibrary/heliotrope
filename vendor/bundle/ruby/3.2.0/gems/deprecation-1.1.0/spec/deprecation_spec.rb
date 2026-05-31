require 'spec_helper'

describe Deprecation do
  class DeprecationTest
    extend Deprecation
    self.deprecation_behavior = :raise

    self.deprecation_horizon = 'release 0.1'


    def a
      1
    end

    deprecation_deprecate :a

    def b

    end

    def c

    end

    def d
      4
    end

    deprecation_deprecate :c, :d

    def e

    end
    deprecation_deprecate :e => { :deprecation_horizon => 'asdf 1.4' }


    def f(x, foo: nil)
      7
    end
    deprecation_deprecate :f
  end
  subject { DeprecationTest.new}

  describe "a" do
    it "should be deprecated" do
      expect { subject.a }.to raise_error /a is deprecated/
    end
  end

  describe "a method that takes positional args and keyword args" do
    around do |example|
      # We need to suppress the raise behavior, so we can ensure the original method is called
      DeprecationTest.deprecation_behavior = :silence
      example.run
      DeprecationTest.deprecation_behavior = :raise
    end

    it "delegates to the original" do
      expect(subject.f 9, foo: 3).to eq 7
    end
  end

  describe "a method that takes no args" do
    around do |example|
      # We need to suppress the raise behavior, so we can ensure the original method is called
      DeprecationTest.deprecation_behavior = :silence
      example.run
      DeprecationTest.deprecation_behavior = :raise
    end

    it "delegates to the original" do
      expect(subject.d).to eq 4
    end
  end

  describe "b" do
    it "should not be deprecated" do
      expect { subject.b }.not_to raise_error
    end
  end

  describe "c,d" do
    it "should be deprecated" do
      expect { subject.c }.to raise_error /c is deprecated/
      expect { subject.d }.to raise_error /d is deprecated/
    end
  end

  describe "e" do
    it "should be deprecated in asdf 1.4" do
      expect { subject.e }.to raise_error /e is deprecated and will be removed from asdf 1.4/
    end
  end

  describe "full callstack" do
    before(:all) do
      Deprecation.show_full_callstack = true
    end

    after(:all) do
      Deprecation.show_full_callstack = false
    end

    it "should" do
      expect { subject.a }.to raise_error /Callstack:/
    end

  end

  describe "warn" do
    class A
      def some_deprecated_method
        Deprecation.warn(A, "some explicit deprecation warning")
        true
      end

      def old_method
        some_deprecated_method
      end
    end

    let(:logger) { double() }

    before(:each) do
      allow(Deprecation).to receive_messages(logger: logger, default_deprecation_behavior: :log)
    end

    it "should provide a useful deprecation trace" do
      expect(logger).to receive(:warn).with(/called from old_method/)
      expect(A.new.old_method).to eq true

    end
  end
end
