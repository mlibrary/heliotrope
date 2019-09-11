# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a Score', type: :system do
  context 'a logged in admin' do
    let!(:press) do
      create(:press, subdomain: Services.score_press,
                     name: 'University of Michigan Open Access Carillon Scores')
    end
    let(:user) { create(:platform_admin) }

    before do
      # Without admin_set creation this spec fails (when run in groups, not alone!) with:
      # Ldp::HttpError:
      #   STATUS: 403 Objects cannot be created under pairtree nodes...
      AdminSet.find_or_create_default_admin_set_id
      login_as user
      stub_out_redis
    end

    it do
      visit new_hyrax_score_path

      expect(page).to have_content "Add New Score"
      click_link "Files" # switch tab
      expect(page).to have_content "Add files"
      expect(page).to have_content "Add folder"
      within('span#addfiles') do
        attach_file("files[]", File.join(fixture_path, 'kitty.tif'), visible: false)
        attach_file("files[]", File.join(fixture_path, 'it.mp4'), visible: false)
        attach_file("files[]", File.join(fixture_path, 'hello.pdf'), visible: false)
      end

      click_link "Descriptions" # switch tab
      fill_in('Title', with: 'My Test Work')
      fill_in('Composer', with: 'Doe, Jane')
      select(press.name, from: 'Publisher (Fulcrum subdivision)')
      check '2' # Octave compass
      select('yes', from: 'Solo')
      check 'Fixed Media' # Amplified electronics
      select('Traditional concert', from: 'Musical presentation')

      click_on('Additional fields')

      fill_in('Abstract or Summary', with: "This is the description of the score")
      check 'F2' # bass bells required
      check 'omit both C#3 and D#3' # bass bells omitted
      select('yes', from: 'Electronics without adjustment')
      select('Vocal ensemble', from: 'Duet or ensemble')
      select('yes', from: 'Recommended for students')
      fill_in('Composer diversity', with: 'female, non-binary')
      check 'worship (non-Chirstian)' # Appropriate Occasiion
      fill_in('Composer contact information', with: "composercontact")
      fill_in('Year of composition', with: '2000')
      fill_in('Number of movements', with: '23')
      check 'North America' # Premiere Status

      choose('score_visibility_open')
      expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
      check('agreement')

      click_on('Save')

      expect(page).to have_content "Your files are being processed by Fulcrum in the background."
      expect(page).to have_content('My Test Work')
      expect(page).to have_content('Doe, Jane')
      expect(page).to have_content('This is the description of the score')

      expect(page).to have_content('Score Information')
      expect(page).to have_content('Octave compass')
      expect(page).to have_content('2')
      expect(page).to have_content('Bass bells required')
      expect(page).to have_content('F2')
      expect(page).to have_content('Bass bells omitted')
      expect(page).to have_content('C#3 and D#3')
      expect(page).to have_content('Solo')
      expect(page).to have_content('yes')
      expect(page).to have_content('Amplified electronics')
      expect(page).to have_content('Fixed Media')
      expect(page).to have_content('Electronics without adjustment')
      expect(page).to have_content('yes')
      expect(page).to have_content('Musical presentation')
      expect(page).to have_content('Traditional concert')
      expect(page).to have_content('Recommended for students')
      expect(page).to have_content('yes')
      expect(page).to have_content('Composer diversity')
      expect(page).to have_content('female, non-binary')
      expect(page).to have_content('Appropriate occasion')
      expect(page).to have_content('worship (non-Chirstian)')
      expect(page).to have_content('Number of movements')
      expect(page).to have_content('23')
      expect(page).to have_content('North America')
    end
  end
end
