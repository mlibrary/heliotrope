# frozen_string_literal: true
require 'spec_helper'
require 'hydra/file_characterization/characterizers/ffprobe'

module Hydra::FileCharacterization::Characterizers
  describe Ffprobe do
    subject { described_class.new(filename) }

    describe 'invalidFile' do
      let(:filename) { fixture_file('nofile.pdf') }
      it "raises an error if the path does not contain the file" do
        expect { subject.call }.to raise_error(Hydra::FileCharacterization::FileNotFoundError)
      end
    end
  end
end
