# frozen_string_literal: true

require 'rails_helper'

# We're overloading clamav to use the "clamby" which is more
# maintained than the "clamav" gem

RSpec.describe HeliotropeVirusScanner do
  describe "#infected" do
    subject { described_class.infected?(file) }

    # The Clamby gem only loads in production so tests are...
    # challenging? Pointless? IDK.

    class Clamby
      def self.virus?(_file)
      end
    end

    let(:file) { double("file") }

    context "the file has a virus" do
      before do
        allow(Clamby).to receive(:virus?).with(file).and_return(true)
      end

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "the file does not have a virus" do
      before do
        allow(Clamby).to receive(:virus?).with(file).and_return(false)
      end

      it "returns false" do
        expect(subject).to be false
      end
    end
  end
end
