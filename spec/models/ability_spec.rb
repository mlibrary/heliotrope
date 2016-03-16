require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  subject { described_class.new(current_user) }

  let(:monograph) { create(:monograph, user: creating_user) }
  let(:section) { create(:section, user: creating_user) }
  let(:file_set) { create(:file_set, user: creating_user) }

  describe 'admin user' do
    # TODO: all signed in users are currently admins
    let(:creating_user) { current_user }
    let(:current_user) { create(:user) }

    it do
      should be_able_to(:create, Monograph.new)
      should be_able_to(:publish, monograph)
      should be_able_to(:read, monograph)
      should be_able_to(:update, monograph)
      should be_able_to(:destroy, monograph)

      should be_able_to(:create, Section.new)
      should be_able_to(:read, section)
      should be_able_to(:update, section)
      should be_able_to(:destroy, section)

      should be_able_to(:create, FileSet.new)
      should be_able_to(:read, file_set)
      should be_able_to(:update, file_set)
      should be_able_to(:destroy, file_set)
    end
  end

  describe 'public user' do
    let(:creating_user) { create(:user) }
    let(:current_user) { User.new }

    context "creating" do
      it do
        should_not be_able_to(:create, Monograph.new)
        should_not be_able_to(:create, Section.new)
        should_not be_able_to(:create, FileSet.new)
      end
    end

    context "read/modify/destroy private things" do
      it do
        should_not be_able_to(:read, monograph)
        should_not be_able_to(:publish, monograph)
        should_not be_able_to(:update, monograph)
        should_not be_able_to(:destroy, monograph)

        should_not be_able_to(:read, section)
        should_not be_able_to(:update, section)
        should_not be_able_to(:destroy, section)

        should_not be_able_to(:read, file_set)
        should_not be_able_to(:update, file_set)
        should_not be_able_to(:destroy, file_set)
      end
    end

    context "read/modify/destroy public things" do
      let(:monograph) { create(:public_monograph, user: creating_user) }
      let(:section) { create(:public_section, user: creating_user) }
      let(:file_set) { create(:public_file_set, user: creating_user) }
      it do
        should be_able_to(:read, monograph)
        should_not be_able_to(:update, monograph)
        should_not be_able_to(:destroy, monograph)

        should be_able_to(:read, section)
        should_not be_able_to(:update, section)
        should_not be_able_to(:destroy, section)

        should be_able_to(:read, file_set)
        should_not be_able_to(:update, file_set)
        should_not be_able_to(:destroy, file_set)
      end
    end
  end
end
