# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RolesController, type: :controller do
  let(:press) { create(:press) }

  describe 'when user does not have access' do
    before { sign_in create(:user) }

    describe 'GET index' do
      it 'denies access' do
        get :index, params: { press_id: press }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end

  describe 'when user is an admin' do
    let(:admin) { create(:press_admin, press: press) }
    let(:user) { create(:user) }
    let(:role) { admin.roles.first } # admin user has a role in the press, see counts below

    before { sign_in admin }

    describe "index" do
      it 'allows index' do
        get :index, params: { press_id: press }
        expect(response).to be_successful
        expect(assigns[:roles].to_a).to eq [role]
      end
    end

    describe 'PATCH update_all' do
      context 'creating new roles' do
        it 'happy path' do
          patch :update_all, params: { press_id: press, 'press' => {
            'roles_attributes' => {
              '0' => { 'role' => 'editor', 'user_key' => user.email }
            }
          } }

          # count here to show that the admin role created by create(:press_admin, press: press) is not affected
          # note that the form actually sends all existing roles through in `roles_attributes` every time,...
          # whether they've changed or not. So the spec exercises the code but doesn't match what actually happens.
          expect(press.roles.count).to eq 2
          expect(press.roles.last.role).to eq 'editor'
          expect(press.roles.last.user.email).to eq user.email
          expect(flash[:notice]).to eq I18n.t(:'helpers.submit.role.added')
        end

        it 'user does not exist' do
          patch :update_all, params: { press_id: press, 'press' => {
            'roles_attributes' => {
              '0' => { 'role' => 'editor', 'user_key' => 'blah@blah.blah' }
            }
          } }

          expect(press.roles.count).to eq 1 # create(:press_admin, press: press)
          expect(response).to be_successful
          expect(flash[:alert]).to eq I18n.t(:'helpers.submit.role.user_missing')
        end

        context 'user already has a role within that press' do
          before { create(:role, resource: Press.first, user: user, role: 'analyst') }

          it 'user already has a role within that press' do
            patch :update_all, params: { press_id: press, 'press' => {
              'roles_attributes' => {
                '0' => { 'role' => 'editor', 'user_key' => user.email }
              }
            } }

            expect(press.roles.count).to eq 2 # create(:press_admin, press: press) and create(:role, resource: Press.first, user: user, role: 'analyst')
            expect(response).to be_successful
            expect(flash[:alert]).to eq I18n.t(:'helpers.submit.role.a_role_exists')
          end
        end
      end

      it 'updates roles' do
        patch :update_all, params: { press_id: press, 'press' => {
          'roles_attributes' => {
            '0' => { 'role' => 'editor', 'id' => role.id }
          }
        } }
        expect(response).to redirect_to press_roles_path(press)
        expect(flash[:notice]).to eq 'User role has been updated.'

        admin.reload

        expect(press.roles.count).to eq 1
        expect(admin.roles.first.role).to eq 'editor'
      end

      it 'ignores empty roles' do
        expect do
          patch :update_all, params: { press_id: press, 'press' => {
            'roles_attributes' => {
              '0' => { 'user_key' => '', 'role' => '' }
            }
          } }
        end.not_to change { press.roles.length }
      end

      it 'authorizes records' do
        allow(controller).to receive(:authorize!).and_raise(CanCan::AccessDenied)
        patch :update_all, params: { press_id: press, 'press' => {
          'roles_attributes' => {
            '0' => { 'role' => 'editor', 'id' => role.id }
          }
        } }
        expect(press.roles.count).to eq 1
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        expect(press.roles.first.role).to eq 'admin'
      end

      it 'destroys records' do
        patch :update_all, params: { press_id: press, 'press' => {
          'roles_attributes' => {
            '0' => { 'role' => 'editor', 'id' => role.id, '_destroy' => '1' }
          }
        } }

        expect(response).to redirect_to press_roles_path(press)
        expect(press.roles).to be_empty
        expect(flash[:notice]).to eq 'User role has been removed.'
      end

      it 'handles failure' do
        allow_any_instance_of(Press).to receive_messages(update: false)
        patch :update_all, params: { press_id: press, 'press' => {
          'roles_attributes' => {
            '0' => { 'role' => 'editor', 'id' => role.id }
          }
        } }
        expect(press.roles.count).to eq 1
        expect(response).to be_successful
        expect(flash[:alert]).to eq 'There was a problem saving the user role(s).'
      end
    end
  end
end
