require 'rails_helper'

describe 'shared/_my_actions.html.erb' do
  let(:press) { Press.first || create(:press) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'a platform-wide admin user' do
    let(:user) { create(:platform_admin) }

    context 'within the scope of a certain press' do
      before do
        assign(:press, press)
        render
      end

      it 'has correct links' do
        expect(rendered).to have_link("Log Out")
        expect(rendered).to have_link("Jobs", href: resque_web_path)
        expect(rendered).to have_link("Embargos", href: embargoes_path)
        expect(rendered).to have_link("Leases", href: leases_path)
        expect(rendered).to have_link("Users", href: press_roles_path(press))
      end
    end

    context 'when there is not a press in scope' do
      before { render }

      it 'has correct links' do
        expect(rendered).to have_link("Log Out")
        expect(rendered).to have_link("Jobs", href: resque_web_path)
        expect(rendered).to have_link("Embargos", href: embargoes_path)
        expect(rendered).to have_link("Leases", href: leases_path)
        expect(rendered).to_not have_link("Users", href: press_roles_path(press))
      end
    end
  end # platform-wide admin user

  context 'a specific press admin user' do
    let(:user) { create(:press_admin, press: press) }

    context 'within the scope of their press' do
      before do
        assign(:press, press)
        render
      end

      it 'has the correct links' do
        expect(rendered).to have_link("Log Out")
        expect(rendered).to have_link("Embargos", href: embargoes_path)
        expect(rendered).to have_link("Leases", href: leases_path)
        expect(rendered).to have_link("Users", href: press_roles_path(press))
      end
    end

    context 'within the scope of a different press' do
      let(:different_press) { create(:press) }
      before do
        assign(:press, different_press)
        render
      end

      it 'has the correct links' do
        expect(rendered).to have_link("Log Out")
        expect(rendered).to have_link("Embargos", href: embargoes_path)
        expect(rendered).to have_link("Leases", href: leases_path)
        expect(rendered).to_not have_link("Users", href: press_roles_path(different_press))
      end
    end
  end # specific press admin user

  context 'a press editor' do
    let(:user) { create(:editor) }

    context 'within the scope of their press' do
      before do
        assign(:press, press)
        render
      end

      it 'has the correct links' do
        expect(rendered).to have_link("Log Out")
        expect(rendered).to have_link("Embargos", href: embargoes_path)
        expect(rendered).to have_link("Leases", href: leases_path)
        expect(rendered).to_not have_link("Users")
      end
    end

    context 'within the scope of a different press' do
      let(:different_press) { create(:press) }
      before do
        assign(:press, different_press)
        render
      end

      it 'has the correct links' do
        expect(rendered).to have_link("Log Out")
        expect(rendered).to have_link("Embargos", href: embargoes_path)
        expect(rendered).to have_link("Leases", href: leases_path)
        expect(rendered).to_not have_link("Users", href: press_roles_path(different_press))
      end
    end
  end # press editor

  context 'non-privileged user' do
    let(:user) { create(:user) }

    context 'within the scope of a certain press' do
      before do
        assign(:press, press)
        render
      end

      it 'has correct links' do
        expect(rendered).to     have_link("Log Out")
        expect(rendered).to_not have_link("Jobs", href: resque_web_path)
        expect(rendered).to_not have_link("Users")

        # TODO: Fix this
        # expect(rendered).to_not have_link("Embargos")
        # expect(rendered).to_not have_link("Leases")
      end
    end

    context 'when there is not a press in scope' do
      before { render }

      it 'has correct links' do
        expect(rendered).to     have_link("Log Out")
        expect(rendered).to_not have_link("Users")
        expect(rendered).to_not have_link("Jobs", href: resque_web_path)

        # TODO: Fix this
        # expect(rendered).to_not have_link("Embargos")
        # expect(rendered).to_not have_link("Leases")
      end
    end
  end # not logged in
end
