# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Press, type: :model do
  describe 'validation' do
    let(:press) { described_class.new }

    it 'must have a subdomain' do
      expect(press.valid?).to eq false
      expect(press.errors.messages[:subdomain]).to eq ["can't be blank"]
    end

    it 'must have a name' do
      expect(press.valid?).to eq false
      expect(press.errors.messages[:name]).to eq ["can't be blank"]
    end

    # it 'must have a logo' do
    #   expect(press.valid?).to eq false
    #   expect(press.errors.messages[:logo_path]).to eq ["You must upload a logo image"]
    # end

    it 'must have a description' do
      expect(press.valid?).to eq false
      expect(press.errors.messages[:description]).to eq ["can't be blank"]
    end

    it 'must have a valid press_url' do
      expect(press.valid?).to eq false
      expect(press.errors.messages[:press_url]).to eq ["can't be blank", "is invalid"]
    end
  end

  describe "to_param" do
    subject { press.to_param }

    let(:press) { build(:press, subdomain: 'umich') }

    it { is_expected.to eq 'umich' }
  end

  describe "#allow_share_links?" do
    subject { press.allow_share_links? }

    context "is set to true" do
      let(:press) { build(:press, subdomain: 'blug', share_links: true) }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when not set" do
      let(:press) { build(:press, subdomain: 'blug') }

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "when set to false" do
      let(:press) { build(:press, subdomain: 'blug', share_links: false) }

      it "returns false" do
        expect(subject).to be false
      end
    end
  end

  describe "roles" do
    subject { press.roles }

    let(:press) { build(:press) }

    it { is_expected.to eq [] }
  end

  describe "a parent press" do
    let(:parent_press) { create(:press, subdomain: "blue") }

    context "with children" do
      let!(:child1) { create(:press, subdomain: "maize", parent_id: parent_press.id) }
      let!(:child2) { create(:press, subdomain: "green", parent_id: parent_press.id) }

      it "the parent press knows it's children presses (that are series, imprints, whatever)" do
        expect(parent_press.children.count).to eq 2
        expect(parent_press.children.first.subdomain).to eq "maize"
        expect(parent_press.children.last.subdomain).to eq "green"
      end

      it "the child presses know their parent" do
        expect(child1.parent).to eq parent_press
        expect(child2.parent).to eq parent_press
      end

      context "a child press can itself have children" do
        # TODO: While this works in the model, it's not really supported anywhere else
        # so if we ever actually need parent -> child -> child we'll have to make some code changes
        let!(:child_child) { create(:press, subdomain: "orange", parent_id: child1.id) }

        it "the child's child press knows it's parent" do
          expect(child_child.parent).to eq child1
        end

        context "while there are many presses now, we can get a list of 'root' or 'ultimate parent' presses" do
          it "there is only be one parent press" do
            expect(Press.parent_presses.count).to be 1
          end
          it "there are 4 presses total" do
            expect(Press.all.count).to be 4
          end
        end
      end
    end
  end

  describe '#agent_type' do
    subject { press.agent_type }

    let(:press) { build(:press) }

    it { is_expected.to eq :Press }
  end

  describe '#agent_id' do
    subject { press.agent_id }

    let(:press) { build(:press) }

    it { is_expected.to be press.id }
  end
end
