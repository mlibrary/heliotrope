# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModelTreeEdge, type: :model do
  context 'Factory Bot' do
    subject(:vertex) { create(:model_tree_edge) }

    it do
      expect(ValidationService.valid_noid?(vertex.parent_noid)).to be true
      expect(ValidationService.valid_noid?(vertex.child_noid)).to be true
    end
  end

  context 'Validation' do
    subject { described_class.new(parent_noid: parent_noid, child_noid: child_noid) }

    context 'blank noids' do
      let(:parent_noid) { nil }
      let(:child_noid) { nil }

      it 'validates presence' do
        expect(subject.valid?).to be false
        expect(subject.errors).to contain_exactly("Child noid can't be blank", "Child noid must be 9 alphanumeric characters", "Parent noid can not be child of self", "Parent noid can't be blank", "Parent noid must be 9 alphanumeric characters")
      end
    end

    context 'invalid noids' do
      let(:parent_noid) { 'invalidnoid' }
      let(:child_noid) { 'noidinvalid' }

      it 'validates format' do
        expect(subject.valid?).to be false
        expect(subject.errors).to contain_exactly("Child noid must be 9 alphanumeric characters", "Parent noid must be 9 alphanumeric characters")
      end
    end

    context 'valid noids' do
      let(:parent_noid) { 'validnoid' }
      let(:child_noid) { 'noidvalid' }

      it 'valid' do
        expect(subject.valid?).to be true
        expect(subject.errors).to be_empty
      end

      context 'second parent' do
        before { create(:model_tree_edge, parent_noid: 'parentone', child_noid: child_noid) }

        it 'invalid' do
          expect(subject.valid?).to be false
          expect(subject.errors).to contain_exactly("Child noid has already been taken")
        end
      end

      context 'second child' do
        before { create(:model_tree_edge, parent_noid: parent_noid, child_noid: 'childnoid') }

        it 'valid' do
          expect(subject.valid?).to be true
          expect(subject.errors).to be_empty
        end
      end

      context 'self loop' do
        let(:child_noid) { 'validnoid' }

        it 'invalid' do
          expect(subject.valid?).to be false
          expect(subject.errors).to contain_exactly("Parent noid can not be child of self")
        end
      end

      context 'simple loop' do
        before { create(:model_tree_edge, parent_noid: child_noid, child_noid: parent_noid) }

        it 'invalid' do
          expect(subject.valid?).to be false
          expect(subject.errors).to contain_exactly("Parent noid can not be child of child")
        end
      end
    end
  end
end
