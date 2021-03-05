# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Publisher, type: :model do
  context 'null publisher' do
    subject { described_class.null_publisher }

    it { is_expected.to be_an_instance_of Sighrax::NullPublisher }
    it { expect(subject.subdomain).to eq 'null_subdomain' }
    it { expect(subject.send(:press)).to eq nil }
    it { expect(subject.valid?).to be false }
    it { expect(subject.resource_type).to eq :NullPublisher }
    it { expect(subject.resource_id).to eq 'null_subdomain' }
    it { expect(subject.resource_token).to eq "#{subject.resource_type}:#{subject.resource_id}" }
    it { expect(subject.parent).to be_an_instance_of Sighrax::NullPublisher }
    it { expect(subject.children).to be_empty }
    it { expect(subject.work_noids(true)).to be_empty }
    it { expect(subject.resource_noids(true)).to be_empty }
    it { expect(subject.user_ids(true)).to be_empty }
  end

  context 'factories' do
    let(:subdomain) { 'publisher' }

    describe '#from_subdomain' do
      subject { described_class.from_subdomain(subdomain) }

      it { is_expected.to eq described_class.null_publisher(subdomain) }

      context 'press' do
        let(:press) { create(:press, subdomain: subdomain) }

        before { press }

        it { is_expected.to eq described_class.send(:new, subdomain, press) }
      end
    end

    describe '#from_press' do
      subject { described_class.from_press(press) }

      let(:press) { double('non press') }

      it { is_expected.to eq described_class.null_publisher }

      context 'press' do
        let(:press) { create(:press, subdomain: subdomain) }

        before { press }

        it { is_expected.to eq described_class.send(:new, subdomain, press) }
      end
    end
  end

  context 'root publisher' do
    subject { described_class.send(:new, subdomain, press) }

    let(:subdomain) { 'root' }
    let(:press) { create(:press, subdomain: subdomain) }

    it { is_expected.to be_an_instance_of described_class }
    it { expect(subject.subdomain).to eq subdomain }
    it { expect(subject.send(:press)).to eq press }
    it { expect(subject.valid?).to be true }
    it { expect(subject.resource_type).to eq :Publisher }
    it { expect(subject.resource_id).to eq subdomain }
    it { expect(subject.resource_token).to eq "#{subject.resource_type}:#{subject.resource_id}" }
    it { expect(subject.parent).to be_an_instance_of Sighrax::NullPublisher }
    it { expect(subject.children).to be_empty }
    it { expect(subject.work_noids(true)).to be_empty }
    it { expect(subject.resource_noids(true)).to be_empty }
    it { expect(subject.user_ids(true)).to be_empty }

    context 'with child' do
      let(:child_subdomain) { 'child' }
      let(:child_press) { create(:press, subdomain: child_subdomain) }

      before do
        press.children << child_press
        press.save
      end

      it { expect(subject.children.count).to eq 1 }
      it { expect(subject.children.first).to eq described_class.from_press child_press }
      it { expect(subject.children.first).to be_an_instance_of described_class }
      it { expect(subject.children.first.parent).to eq subject }
    end

    context 'with user' do
      let(:press_admin) { create(:press_admin, press: press) }

      before { press_admin }

      it { expect(subject.user_ids(true)).to contain_exactly(press_admin.id) }

      context 'with child user' do
        let(:child_subdomain) { 'child' }
        let(:child_press) { create(:press, subdomain: child_subdomain) }
        let(:child_press_admin) { create(:press_admin, press: child_press) }

        before do
          press.children << child_press
          press.save
          child_press_admin
        end

        it { expect(subject.user_ids).to contain_exactly(press_admin.id) }
        it { expect(subject.user_ids(true)).to contain_exactly(press_admin.id, child_press_admin.id) }
      end
    end

    context 'with work and resource' do
      let(:monograph) do
        create(:public_monograph, press: press.subdomain) do |m|
          m.ordered_members << file_set
          m.save
          m
        end
      end
      let(:file_set) { create(:public_file_set) }

      before { monograph }

      it { expect(subject.work_noids(true)).to contain_exactly(monograph.id) }
      it { expect(subject.resource_noids(true)).to contain_exactly(file_set.id) }

      context 'with child work and resource' do
        let(:child_subdomain) { 'child' }
        let(:child_press) { create(:press, subdomain: child_subdomain) }
        let(:child_score) do
          create(:public_score, press: child_press.subdomain) do |m|
            m.ordered_members << child_file_set
            m.save
            m
          end
        end
        let(:child_file_set) { create(:public_file_set) }

        before do
          press.children << child_press
          press.save
          child_score
        end

        it { expect(subject.work_noids).to contain_exactly(monograph.id) }
        it { expect(subject.resource_noids).to contain_exactly(file_set.id) }
        it { expect(subject.work_noids(true)).to contain_exactly(monograph.id, child_score.id) }
        it { expect(subject.resource_noids(true)).to contain_exactly(file_set.id, child_file_set.id) }
      end
    end
  end
end
