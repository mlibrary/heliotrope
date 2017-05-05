# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubBrandsController, type: :controller do
  let(:press) { create :press }
  let(:another_press) { create :press }

  context 'a platform-wide admin user' do
    let(:user) { create(:platform_admin) }

    before { sign_in user }

    describe '#new' do
      before { get :new, params: { press_id: press } }

      it 'displays the form for a new sub-brand' do
        expect(response).to render_template :new
        expect(response).to be_success
        expect(assigns[:press]).to eq press
        expect(assigns[:sub_brand].press).to eq press
      end
    end

    describe '#edit' do
      let(:sub_brand) { create :sub_brand, press: press }

      before { get :edit, params: { press_id: sub_brand.press, id: sub_brand } }

      it 'displays the form to edit the sub-brand' do
        expect(response).to render_template :edit
        expect(response).to be_success
        expect(assigns[:press]).to eq press
        expect(assigns[:sub_brand]).to eq sub_brand
      end
    end

    describe '#update' do
      let(:sub_brand) { create :sub_brand, press: press, title: 'old name' }

      before { patch :update, params: { press_id: sub_brand.press, id: sub_brand, sub_brand: params } }

      context 'with correct inputs' do
        let(:params) { { title: 'new name' } }

        it 'updates the record' do
          expect(response).to redirect_to press_sub_brand_path(press, sub_brand)
          expect(sub_brand.reload.title).to eq 'new name'
        end
      end

      context 'with bad inputs' do
        let(:params) { { title: nil } }

        it 're-renders the form so user can correct errors' do
          expect(response).to render_template :edit
          expect(sub_brand.reload.title).to eq 'old name'
        end
      end
    end

    describe '#create' do
      context 'with correct inputs' do
        let(:params) do
          { press_id: press.subdomain,
            sub_brand: { title: 'Works of W. Shakespeare' } }
        end

        it 'creates the record' do
          expect {
            post :create, params: params
          }.to change { SubBrand.count }.by(1)

          sub_brand = assigns[:sub_brand]

          expect(sub_brand.press).to eq press
          expect(sub_brand.title).to eq params[:sub_brand][:title]
          expect(response).to redirect_to press_sub_brand_path(press, sub_brand)
        end
      end

      context 'with bad inputs' do
        let(:params) do
          { press_id: press.subdomain,
            sub_brand: { title: nil } }
        end

        it 're-renders the form so user can correct errors' do
          expect {
            post :create, params: params
          }.to change { SubBrand.count }.by(0)

          expect(response).to render_template :new
        end
      end
    end
  end  # platform-wide admin user

  context 'a press-level admin user' do
    let(:user) { create(:press_admin, press: press) }

    before { sign_in user }

    context 'within my own press' do
      describe '#new' do
        before { get :new, params: { press_id: press } }

        it 'displays the form for a new sub-brand' do
          expect(response).to render_template :new
          expect(response).to be_success
          expect(assigns[:press]).to eq press
          expect(assigns[:sub_brand].press).to eq press
        end
      end
    end

    context 'within another press' do
      describe '#new' do
        before { get :new, params: { press_id: another_press } }

        it 'denies access' do
          expect(flash.alert).to match(/You are not authorized/)
          expect(response).to redirect_to root_path
        end
      end

      describe '#edit' do
        let(:sub_brand) { create :sub_brand, press: another_press }

        before { get :edit, params: { press_id: another_press, id: sub_brand } }

        it 'denies access' do
          expect(response.code).to eq '401'
          expect(response).to render_template :unauthorized
        end
      end

      describe '#update' do
        let(:sub_brand) { create :sub_brand, press: another_press, title: 'old name' }
        let(:params) { { title: 'new name' } }

        before { patch :update, params: { press_id: sub_brand.press, id: sub_brand, sub_brand: params } }

        it 'denies access' do
          expect(response.code).to eq '401'
          expect(response).to render_template :unauthorized
          expect(sub_brand.reload.title).to eq 'old name'
        end
      end
    end
  end  # press-level admin user

  context 'a press-level editor' do
    let(:user) { create(:editor) }

    before { sign_in user }

    describe '#new' do
      before { get :new, params: { press_id: press } }

      it 'denies access' do
        expect(flash.alert).to match(/You are not authorized/)
        expect(response).to redirect_to root_path
      end
    end

    describe '#edit' do
      let(:sub_brand) { create :sub_brand, press: press }

      before { get :edit, params: { press_id: sub_brand.press, id: sub_brand } }

      it 'denies access' do
        expect(response.code).to eq '401'
        expect(response).to render_template :unauthorized
      end
    end

    describe '#update' do
      let(:sub_brand) { create :sub_brand, press: press, title: 'old name' }
      let(:params) { { title: 'new name' } }

      before { patch :update, params: { press_id: sub_brand.press, id: sub_brand, sub_brand: params } }

      it 'denies access' do
        expect(response.code).to eq '401'
        expect(response).to render_template :unauthorized
        expect(sub_brand.reload.title).to eq 'old name'
      end
    end
  end  # press editor

  context 'not logged in' do
    let(:user) { nil }
    let(:sub_brand) { create :sub_brand }

    describe '#show' do
      before { get :show, params: { press_id: sub_brand.press, id: sub_brand } }

      it 'is successful' do
        expect(response).to render_template :show
        expect(response).to be_success
        expect(assigns[:press]).to eq sub_brand.press
        expect(assigns[:sub_brand]).to eq sub_brand
      end
    end
  end  # user not logged in
end
