# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PressesController, type: :controller do
  describe "#index" do
    context "as a signed in user" do
      let(:user) { create(:user) }
      let!(:press) { create(:press) }

      before { sign_in user }

      it 'shows the presses' do
        get :index
        expect(response).to be_success
        expect(assigns[:presses]).to include press
      end
    end
  end

  context 'unauthenticated user create/edit' do
    describe 'can\'t access new' do
      before { get :new }
      it { expect(response).to redirect_to new_user_session_path }
    end

    describe 'can\'t access edit' do
      let!(:press) { create(:press) }
      before { get :edit, params: { id: press.subdomain } }
      it { expect(response).to redirect_to new_user_session_path }
    end
  end

  context 'a platform-wide admin user create/edit' do
    let(:user) { create(:platform_admin) }
    before { sign_in user }

    describe '#new' do
      before { get :new }

      it 'displays the form for a new press' do
        expect(response).to render_template :new
        expect(response).to be_success
      end
    end

    describe '#edit' do
      let(:press) { create :press }

      before { get :edit, params: { id: press.subdomain } }

      it 'displays the form to edit the press' do
        expect(response).to render_template :edit
        expect(response).to be_success
      end
    end
  end

  context 'a press admin user create/edit' do
    let(:user) { create(:press_admin) }
    before { sign_in user }

    describe '#new' do
      before { get :new }

      it 'cannot access the form for a new press' do
        expect(response).to_not be_success
      end
    end

    describe '#edit' do
      let(:press) { create :press }
      let(:user) { create(:press_admin, press: press) }
      before { get :edit, params: { id: press.subdomain } }

      it 'displays the form to edit the press' do
        expect(response).to render_template :edit
        expect(response).to be_success
      end
    end
  end
end
