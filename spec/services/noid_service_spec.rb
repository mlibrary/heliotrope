# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NoidService do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it 'is expected' do
      is_expected.to be_an_instance_of(NoidServiceNullObject)
      expect(subject.valid?).to be false
      expect(subject.noid).to eq 'null_noid'
      expect(subject.type).to be :null_object
      expect(subject.model).to be_empty
      expect(subject.title).to eq 'null_noid'
    end
  end

  describe '#from_noid' do
    subject { described_class.from_noid(noid) }

    context 'nil noid' do
      let(:noid) { nil }

      it { is_expected.to be_an_instance_of(NoidServiceNullObject) }
    end

    context 'invalid noid' do
      let(:noid) { 'invalid' }

      it { is_expected.to be_an_instance_of(NoidServiceNullObject) }
    end

    context 'valid noid' do
      let(:noid) { 'validnoid' }
      let(:model) { {} }

      before { allow(ActiveFedora::SolrService).to receive(:query).with("{!terms f=id}#{noid}", rows: 1).and_return([model]) }

      it { is_expected.to be_an_instance_of(NoidServiceNullObject) }

      context 'standard error' do
        before { allow(ActiveFedora::SolrService).to receive(:query).with("{!terms f=id}#{noid}", rows: 1).and_raise(StandardError) }

        it { is_expected.to be_an_instance_of(NoidServiceNullObject) }
      end

      context 'object' do
        let(:model) { { "solr" => "document" } }

        it 'is expected' do
          is_expected.to be_an_instance_of(described_class)
          expect(subject.valid?).to be true
          expect(subject.noid).to eq noid
          expect(subject.type).to be :object
          expect(subject.model).to be model
          expect(subject.title).to eq noid
        end
      end

      context 'model' do
        let(:model) do
          {
            "has_model_ssim" => [type],
            "title_tesim" => [title]
          }
        end
        let(:type) {}
        let(:title) {}

        it 'is expected' do
          is_expected.to be_an_instance_of(described_class)
          expect(subject.valid?).to be true
          expect(subject.noid).to eq noid
          expect(subject.type).to be :object
          expect(subject.model).to be model
          expect(subject.title).to eq noid
        end

        context 'monograph' do
          let(:type) { 'Monograph' }
          let(:title) { 'Monograph Title' }

          it 'is expected' do
            is_expected.to be_an_instance_of(described_class)
            expect(subject.valid?).to be true
            expect(subject.noid).to eq noid
            expect(subject.type).to be :mongraph
            expect(subject.model).to be model
            expect(subject.title).to eq title
          end
        end

        context 'file_set' do
          let(:type) { 'FileSet' }
          let(:title) { 'FileSet Title' }

          it 'is expected' do
            is_expected.to be_an_instance_of(described_class)
            expect(subject.valid?).to be true
            expect(subject.noid).to eq noid
            expect(subject.type).to be :file_set
            expect(subject.model).to be model
            expect(subject.title).to eq title
          end
        end

        context 'unknown' do
          let(:type) { 'Generic' }
          let(:title) { 'Generic Title' }

          it 'is expected' do
            is_expected.to be_an_instance_of(described_class)
            expect(subject.valid?).to be true
            expect(subject.noid).to eq noid
            expect(subject.type).to be :unknown
            expect(subject.model).to be model
            expect(subject.title).to eq title
          end
        end
      end
    end
  end
end
