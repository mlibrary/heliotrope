# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  subject { described_class.new(current_user) }

  let(:press) { create(:press) }
  let(:sub_brand) { create(:sub_brand, press: press) }

  let(:monograph) { create(:monograph, user: creating_user, press: press.subdomain) }
  let(:file_set) { create(:file_set, user: creating_user) }

  let(:monograph_presenter) do
    Hyrax::MonographPresenter.new(SolrDocument.new(id: monograph.id, press_tesim: press.subdomain), described_class.new(creating_user))
  end
  let(:file_set_presenter) do
    Hyrax::FileSetPresenter.new(SolrDocument.new(id: file_set.id, monograph_id_ssim: monograph.id), described_class.new(creating_user))
  end

  describe 'a platform-wide admin user' do
    let(:creating_user) { current_user }
    let(:current_user) { create(:platform_admin) }
    let(:role) { create(:role) }
    let(:another_user) { create(:user) }
    let(:another_user_monograph) { create(:monograph, user: another_user, press: press.subdomain) }
    let(:another_user_monograph_presenter) do
      Hyrax::MonographPresenter.new(SolrDocument.new(id: another_user_monograph.id, press_tesim: press.subdomain), described_class.new(another_user))
    end

    it do
      is_expected.to be_able_to(:create, Monograph.new)
      is_expected.to be_able_to(:publish, monograph)
      is_expected.to be_able_to(:read, monograph)
      is_expected.to be_able_to(:update, monograph)
      is_expected.to be_able_to(:destroy, monograph)
      is_expected.to be_able_to(:update, monograph_presenter)

      is_expected.to be_able_to(:create, FileSet.new)
      is_expected.to be_able_to(:read, file_set)
      is_expected.to be_able_to(:update, file_set)
      is_expected.to be_able_to(:destroy, file_set)
      is_expected.to be_able_to(:update, file_set_presenter)

      is_expected.to be_able_to(:read, role)
      is_expected.to be_able_to(:update, role)
      is_expected.to be_able_to(:destroy, role)

      is_expected.to be_able_to(:create, Press.new)
      is_expected.to be_able_to(:update, press)
      is_expected.to be_able_to(:manage, sub_brand)
    end

    it "can read, update, publish or destroy a monograph created by another user" do
      is_expected.to be_able_to(:read, another_user_monograph)
      is_expected.to be_able_to(:update, another_user_monograph)
      is_expected.to be_able_to(:publish, another_user_monograph)
      is_expected.to be_able_to(:destroy, another_user_monograph)
      is_expected.to be_able_to(:update, another_user_monograph_presenter)
    end

    context "ApplicationPresenter" do
      it { is_expected.to be_able_to(:read, ApplicationPresenter.new(current_user)) }
    end

    context "DashboardPresenter" do
      it { is_expected.to be_able_to(:read, DashboardPresenter.new(current_user)) }
    end

    context "PublisherPresenter" do
      let(:publisher) { double("publisher") }
      it { is_expected.to be_able_to(:read, PublisherPresenter.new(current_user, publisher)) }
    end

    context "PublishersPresenter" do
      it { is_expected.to be_able_to(:read, PublishersPresenter.new(current_user)) }
    end

    context "RepositoryPresenter" do
      it { is_expected.to be_able_to(:read, RepositoryPresenter.new(current_user)) }
    end

    context "RolePresenter" do
      it { is_expected.to be_able_to(:read, RolePresenter.new(current_user.roles.first, current_user, current_user)) }
      it { is_expected.to be_able_to(:read, RolePresenter.new(another_user.roles.first, another_user, current_user)) }
    end

    context "RolesPresenter" do
      it { is_expected.to be_able_to(:read, RolesPresenter.new(current_user, current_user)) }
      it { is_expected.to be_able_to(:read, RolesPresenter.new(another_user, current_user)) }
    end

    context "UserPresenter" do
      it { is_expected.to be_able_to(:read, UserPresenter.new(another_user, current_user)) }
    end

    context "UsersPresenter" do
      it { is_expected.to be_able_to(:read, UsersPresenter.new(current_user)) }
    end
  end

  describe 'a press-admin' do
    let(:my_press) { create(:press) }
    let(:other_press) { create(:press) }
    let(:my_sub_brand) { create(:sub_brand, press: my_press, title: ['My own sub-brand']) }
    let(:other_sub_brand) { create(:sub_brand, press: other_press, title: ["Someone else's sub-brand"]) }
    let(:current_user) { create(:press_admin, press: my_press) }

    it do
      is_expected.to_not be_able_to(:create, Press.new)
      is_expected.to     be_able_to(:update, my_press)
      is_expected.to_not be_able_to(:update, other_press)
      is_expected.to     be_able_to(:manage, my_sub_brand)
      is_expected.to_not be_able_to(:manage, other_sub_brand)
      is_expected.to     be_able_to(:read, other_sub_brand)
    end

    context "roles" do
      let(:my_press_role) { create(:role, resource: my_press) }
      let(:other_press_role) { create(:role) }
      it do
        is_expected.to be_able_to(:read, my_press_role)
        is_expected.to be_able_to(:update, my_press_role)
        is_expected.to be_able_to(:destroy, my_press_role)

        is_expected.to_not be_able_to(:read, other_press_role)
        is_expected.to_not be_able_to(:update, other_press_role)
        is_expected.to_not be_able_to(:destroy, other_press_role)
      end
    end

    context "creating" do
      let(:monograph_for_my_press) { Monograph.new(press: my_press.subdomain) }
      let(:monograph_for_other_press) { Monograph.new(press: other_press.subdomain) }

      it do
        is_expected.to be_able_to(:create, monograph_for_my_press)
        is_expected.to_not be_able_to(:create, monograph_for_other_press)
      end
    end

    context "updating" do
      let(:my_presenter) { Hyrax::MonographPresenter.new(SolrDocument.new(id: 'my_id', press_tesim: my_press.subdomain), subject) }
      let(:other_presenter) { Hyrax::MonographPresenter.new(SolrDocument.new(id: 'other_id', press_tesim: other_press.subdomain), subject) }

      it do
        is_expected.to be_able_to(:update, my_presenter)
        is_expected.to_not be_able_to(:update, other_presenter)
      end
    end

    context "ApplicationPresenter" do
      it { is_expected.to_not be_able_to(:read, ApplicationPresenter.new(current_user)) }
    end

    context "DashboardPresenter" do
      it { is_expected.to_not be_able_to(:read, DashboardPresenter.new(current_user)) }
    end

    context "PublisherPresenter" do
      let(:publisher) { double("publisher") }
      it { is_expected.to_not be_able_to(:read, PublisherPresenter.new(current_user, publisher)) }
    end

    context "PublishersPresenter" do
      it { is_expected.to_not be_able_to(:read, PublishersPresenter.new(current_user)) }
    end

    context "RepositoryPresenter" do
      it { is_expected.to_not be_able_to(:read, RepositoryPresenter.new(current_user)) }
    end

    describe "RolePresenter" do
      let(:my_press_user) { create(:editor, press: my_press) }
      let(:other_press_user) { create(:editor, press: other_press) }
      it { is_expected.to     be_able_to(:read, RolePresenter.new(current_user.roles.first, current_user, current_user)) }
      it { is_expected.to     be_able_to(:read, RolePresenter.new(my_press_user.roles.first, my_press_user, current_user)) }
      it { is_expected.to_not be_able_to(:read, RolePresenter.new(other_press_user.roles.first, other_press_user, current_user)) }
    end

    describe "RolesPresenter" do
      let(:another_user) { double("another_user") }
      it { is_expected.to be_able_to(:read, RolesPresenter.new(current_user, current_user)) }
      it { is_expected.to be_able_to(:read, RolesPresenter.new(another_user, current_user)) }
    end

    describe "UserPresenter" do
      let(:my_press_user) { create(:editor, press: my_press) }
      let(:other_press_user) { create(:editor, press: other_press) }
      it { is_expected.to     be_able_to(:read, UserPresenter.new(current_user, current_user)) }
      it { is_expected.to     be_able_to(:read, UserPresenter.new(my_press_user, current_user)) }
      it { is_expected.to_not be_able_to(:read, UserPresenter.new(other_press_user, current_user)) }
    end

    describe "UsersPresenter" do
      it { is_expected.to be_able_to(:read, UsersPresenter.new(current_user)) }
    end
  end

  describe 'a press editor' do
    let(:my_press) { create(:press) }
    let(:my_sub_brand) { create(:sub_brand, press: my_press, title: ['My own sub-brand']) }
    let(:current_user) { create(:editor, press: my_press) }
    let(:monograph_for_my_press) { Monograph.new(press: my_press.subdomain) }

    it do
      is_expected.to_not be_able_to(:create, Press.new)
      is_expected.to_not be_able_to(:update, my_press)
      is_expected.to_not be_able_to(:create, monograph_for_my_press)
      is_expected.to_not be_able_to(:manage, my_sub_brand)
      is_expected.to     be_able_to(:read, my_sub_brand)
    end

    context "ApplicationPresenter" do
      it { is_expected.to_not be_able_to(:read, ApplicationPresenter.new(current_user)) }
    end

    context "DashboardPresenter" do
      it { is_expected.to_not be_able_to(:read, DashboardPresenter.new(current_user)) }
    end

    context "PublisherPresenter" do
      let(:publisher) { double("publisher") }
      it { is_expected.to_not be_able_to(:read, PublisherPresenter.new(current_user, publisher)) }
    end

    context "PublishersPresenter" do
      it { is_expected.to_not be_able_to(:read, PublishersPresenter.new(current_user)) }
    end

    context "RepositoryPresenter" do
      it { is_expected.to_not be_able_to(:read, RepositoryPresenter.new(current_user)) }
    end

    describe "RolePresenter" do
      let(:my_press_user) { create(:editor, press: my_press) }
      let(:other_press_user) { create(:editor, press: create(:press)) }
      it { is_expected.to     be_able_to(:read, RolePresenter.new(current_user.roles.first, current_user, current_user)) }
      it { is_expected.to_not be_able_to(:read, RolePresenter.new(my_press_user.roles.first, my_press_user, current_user)) }
      it { is_expected.to_not be_able_to(:read, RolePresenter.new(other_press_user.roles.first, other_press_user, current_user)) }
    end

    describe "RolesPresenter" do
      let(:another_user) { double("another_user") }
      it { is_expected.to be_able_to(:read, RolesPresenter.new(current_user, current_user)) }
      it { is_expected.to be_able_to(:read, RolesPresenter.new(another_user, current_user)) }
    end

    describe "UserPresenter" do
      let(:my_press_user) { create(:editor, press: my_press) }
      let(:other_press_user) { create(:editor, press: create(:press)) }
      it { is_expected.to     be_able_to(:read, UserPresenter.new(current_user, current_user)) }
      it { is_expected.to_not be_able_to(:read, UserPresenter.new(my_press_user, current_user)) }
      it { is_expected.to_not be_able_to(:read, UserPresenter.new(other_press_user, current_user)) }
      it { is_expected.to_not be_able_to(:read, UserPresenter.new(create(:user), current_user)) }
    end

    describe "UsersPresenter" do
      it { is_expected.to_not be_able_to(:read, UsersPresenter.new(current_user)) }
    end
  end

  describe 'public user' do
    let(:creating_user) { create(:user) }
    let(:current_user) { User.new }

    context "creating" do
      it do
        is_expected.to_not be_able_to(:create, Monograph.new)
        is_expected.to_not be_able_to(:create, FileSet.new)
      end
    end

    context "presses" do
      it do
        is_expected.to_not be_able_to(:create, Press.new)
        is_expected.to     be_able_to(:index, Press)
        is_expected.to     be_able_to(:read, press)
        is_expected.to_not be_able_to(:update, press)
        is_expected.to_not be_able_to(:manage, sub_brand)
        is_expected.to     be_able_to(:read, sub_brand)
      end
    end

    context "read/modify/destroy private things" do
      it do
        is_expected.to_not be_able_to(:read, monograph)
        is_expected.to_not be_able_to(:publish, monograph)
        is_expected.to_not be_able_to(:update, monograph)
        is_expected.to_not be_able_to(:destroy, monograph)

        is_expected.to_not be_able_to(:read, file_set)
        is_expected.to_not be_able_to(:update, file_set)
        is_expected.to_not be_able_to(:destroy, file_set)
      end
    end

    context "read/modify/destroy public things" do
      let(:monograph) { create(:public_monograph, user: creating_user, press: press.subdomain) }
      let(:file_set) { create(:public_file_set, user: creating_user) }
      it do
        is_expected.to be_able_to(:read, monograph)
        is_expected.to_not be_able_to(:update, monograph)
        is_expected.to_not be_able_to(:destroy, monograph)
        is_expected.to_not be_able_to(:publish, monograph)

        is_expected.to be_able_to(:read, file_set)
        is_expected.to_not be_able_to(:update, file_set)
        is_expected.to_not be_able_to(:destroy, file_set)
      end
    end

    context "admin only things" do
      let(:role) { create(:role) }
      it do
        is_expected.to_not be_able_to(:read, role)
        is_expected.to_not be_able_to(:update, role)
        is_expected.to_not be_able_to(:destroy, role)
      end
    end

    context "ApplicationPresenter" do
      it { is_expected.to_not be_able_to(:read, ApplicationPresenter.new(current_user)) }
    end

    context "DashboardPresenter" do
      it { is_expected.to_not be_able_to(:read, DashboardPresenter.new(current_user)) }
    end

    context "PublisherPresenter" do
      let(:publisher) { double("publisher") }
      it { is_expected.to_not be_able_to(:read, PublisherPresenter.new(current_user, publisher)) }
    end

    context "PublishersPresenter" do
      it { is_expected.to_not be_able_to(:read, PublishersPresenter.new(current_user)) }
    end

    context "RepositoryPresenter" do
      it { is_expected.to_not be_able_to(:read, RepositoryPresenter.new(current_user)) }
    end

    describe "RolePresenter" do
      let(:another_user) { create(:editor, press: create(:press)) }
      it { is_expected.to     be_able_to(:read, RolePresenter.new(current_user.roles.first, current_user, current_user)) }
      it { is_expected.to_not be_able_to(:read, RolePresenter.new(another_user.roles.first, another_user, current_user)) }
    end

    describe "RolesPresenter" do
      let(:another_user) { double("another_user") }
      it { is_expected.to be_able_to(:read, RolesPresenter.new(current_user, current_user)) }
      it { is_expected.to be_able_to(:read, RolesPresenter.new(another_user, current_user)) }
    end

    describe "UserPresenter" do
      it { is_expected.to     be_able_to(:read, UserPresenter.new(current_user, current_user)) }
      it { is_expected.to_not be_able_to(:read, UserPresenter.new(create(:user), current_user)) }
    end

    describe "UsersPresenter" do
      it { is_expected.to_not be_able_to(:read, UsersPresenter.new(current_user)) }
    end
  end
end
