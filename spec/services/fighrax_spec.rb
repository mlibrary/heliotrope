# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Fighrax do
  describe '#facotry' do
    subject { described_class.factory(uri) }

    let(:uri) { 'validuri' }

    it 'null_node' do
      is_expected.to be_an_instance_of(Fighrax::NullNode)
      expect(subject.uri).to be uri
    end

    context 'standard error' do
      before { allow(FedoraNode).to receive(:find_by).with(uri: uri).and_raise(StandardError) }

      it 'null_node' do
        is_expected.to be_an_instance_of(Fighrax::NullNode)
        expect(subject.uri).to be uri
      end
    end

    context 'Node' do
      let(:fedora_node) { double('fedora_node', jsonld: jsonld) }
      let(:jsonld) { { 'hasModel' => model_type } }
      let(:model_type) { nil }

      before { allow(FedoraNode).to receive(:find_by).with(uri: uri).and_return(fedora_node) }

      it do
        is_expected.to be_an_instance_of(Fighrax::Node)
        expect(subject.uri).to be uri
        expect(subject.jsonld).to be jsonld
      end

      context 'Model' do
        let(:model_type) { 'Unknown' }

        it { is_expected.to be_an_instance_of(Fighrax::Model) }

        context 'AccessControl' do
          let(:model_type) { 'Hydra::AccessControl' }

          it { is_expected.to be_an_instance_of(Fighrax::AccessControl) }
        end

        context 'AdminSet' do
          let(:model_type) { 'AdminSet' }

          it { is_expected.to be_an_instance_of(Fighrax::AdminSet) }
        end

        context 'File' do
          let(:model_type) { 'File' }

          it { is_expected.to be_an_instance_of(Fighrax::File) }
        end

        context 'FileSet' do
          let(:model_type) { 'FileSet' }

          it { is_expected.to be_an_instance_of(Fighrax::FileSet) }
        end

        context 'Monograph' do
          let(:model_type) { 'Monograph' }

          it { is_expected.to be_an_instance_of(Fighrax::Monograph) }
        end
      end
    end
  end
end
