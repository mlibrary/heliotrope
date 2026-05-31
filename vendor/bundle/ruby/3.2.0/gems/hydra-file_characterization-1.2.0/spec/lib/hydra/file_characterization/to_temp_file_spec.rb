# frozen_string_literal: true
require 'spec_helper'
require 'hydra/file_characterization/to_temp_file'

module Hydra::FileCharacterization
  describe 'ToTempFile' do
    let(:content) { "This is the content of the file." }
    let(:filename) { "hello.rb" }

    describe '.open' do
      subject { ToTempFile }
      it 'creates a tempfile then unlinks it' do
        subject.open(filename, content) do |temp_file|
          @temp_file = temp_file
          expect(File.exist?(@temp_file.path)).to eq true
          expect(File.extname(@temp_file.path)).to include '.rb'
        end
        expect(@temp_file.path).to eq nil
      end
    end

    describe 'instance' do
      subject { ToTempFile.new(filename) }
      it 'create a tempfile that exists' do
        subject.call(content) do |temp_file|
          temp_file.rewind
          expect(temp_file.read).to eq(content)
          @temp_file = temp_file
          expect(File.exist?(@temp_file.path)).to eq true
          expect(File.extname(@temp_file.path)).to include '.rb'
        end
        expect(@temp_file.path).to eq nil
      end

      context 'with file handle' do
        let(:filename) { __FILE__ }
        let(:content) { File.open(__FILE__, 'rb') }
        it 'works' do
          subject.call(content) do |temp_file|
            temp_file.rewind
            expect(temp_file.read).to eq File.read(__FILE__)
          end
        end
      end
    end
  end
end
