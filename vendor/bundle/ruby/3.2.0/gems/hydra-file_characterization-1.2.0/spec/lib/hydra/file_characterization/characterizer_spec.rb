# frozen_string_literal: true
require 'spec_helper'

module Hydra::FileCharacterization
  describe Characterizer do
    subject { characterizer }
    let(:filename) { __FILE__ }
    let(:instance_tool_path) { nil }
    let(:class_tool_path) { nil }

    let(:characterizer) { described_class.new(filename, instance_tool_path) }
    around do |example|
      described_class.tool_path = class_tool_path
      example.run
      described_class.tool_path = nil
    end

    context 'call' do
      context 'with missing file' do
        let(:filename) { '/dev/path/to/bogus/file' }
        it 'raises FileNotFoundError' do
          expect { subject.call }.to raise_error(FileNotFoundError)
        end
      end

      context 'with a callable tool path' do
        let(:class_tool_path) { ->(filename) { [filename, :output] } }
        it 'raises FileNotFoundError' do
          expect(subject.call).to eq [filename, :output]
        end
      end
    end

    context 'tool_path' do
      subject { characterizer.tool_path }

      context 'with custom instance tool_path' do
        let(:instance_tool_path) { '/arbitrary/path' }
        let(:class_tool_path) { '/a_different/path' }

        it { is_expected.to eq instance_tool_path }
      end

      context 'with custom class tool_path' do
        let(:instance_tool_path) { nil }
        let(:class_tool_path) { '/a_different/path' }

        it { is_expected.to eq class_tool_path }
      end

      context 'without a specified tool_path' do
        it { is_expected.to eq 'characterizer' }
      end
    end
  end
end
