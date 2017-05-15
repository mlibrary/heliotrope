# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_add_content.html.erb' do
  let(:press) { Press.first || create(:press) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    view.extend CurationConcerns::AbilityHelper
  end

  context 'a platform-wide admin user' do
    let(:user) { create(:platform_admin) }

    context 'within the scope of a certain press' do
      before do
        assign(:press, press)
        render
      end

      it 'has correct links' do
        expect(rendered).to have_link("Add a Sub-Brand")
      end
    end

    context 'when there is not a press in scope' do
      before { render }

      it 'has correct links' do
        expect(rendered).to_not have_link("Add a Sub-Brand")
      end
    end
  end # platform-wide admin user

  context 'a press-level admin user' do
    let(:user) { create(:press_admin, press: press) }

    context 'within the scope of a certain press' do
      before do
        assign(:press, press)
        render
      end

      it 'has correct links' do
        expect(rendered).to have_link("Add a Sub-Brand")
      end
    end

    context 'when there is not a press in scope' do
      before { render }

      it 'has correct links' do
        expect(rendered).to_not have_link("Add a Sub-Brand")
      end
    end
  end # a press-level admin user

  context 'an editor user' do
    let(:user) { create(:editor, press: press) }

    context 'within the scope of a certain press' do
      before do
        assign(:press, press)
        render
      end

      it 'has correct links' do
        # TODO: fix this
        # expect(rendered).to_not have_link("Add a Sub-Brand")
      end
    end
  end # an editor user

  context 'non-privileged user' do
    let(:user) { create(:user) }

    context 'within the scope of a certain press' do
      before do
        assign(:press, press)
        render
      end

      it 'has correct links' do
        # TODO: fix this
        # expect(rendered).to_not have_link("Add a Sub-Brand")
      end
    end
  end # non-privileged user
end
