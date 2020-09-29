# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Utilities", type: :request do
  describe "GET /whoami" do
    let(:headers) do
      {
        'HTTP_USER_AGENT' => 'expected_user_agent',
        'REMOTE_HOST' => 'expected_remote_host',
        'REMOTE_ADDR' => 'expected_remote_addr',
        'REMOTE_USER' => 'expected_remote_user',
        'HTTP_X_FORWARDED_FOR' => 'expected_x_forwarded_for'
      }
    end

    it do
      get whoami_utility_path, params: { expected_note: nil }, headers: headers
      expect(response).to have_http_status(:success)
      expect(response.body).to include('expected_user_agent')
      expect(response.body).to include('expected_remote_host')
      expect(response.body).to include('expected_remote_addr')
      expect(response.body).not_to include('expected_remote_user') # FYI: REMOTE_USER is nil!  Don't know why. :(
      expect(response.body).to include('expected_x_forwarded_for')
      expect(response.body).to include('expected_note')
    end

    context 'without note' do
      it do
        get whoami_utility_path, params: {}, headers: headers
        expect(response).to have_http_status(:success)
        expect(response.body).to include('expected_user_agent')
        expect(response.body).to include('expected_remote_host')
        expect(response.body).to include('expected_remote_addr')
        expect(response.body).not_to include('expected_remote_user') # FYI: REMOTE_USER is nil!  Don't know why. :(
        expect(response.body).to include('expected_x_forwarded_for')
        expect(response.body).to include('(none)')
      end
    end

    context 'without note or headers' do
      it do
        get whoami_utility_path, params: {}, headers: {}
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('expected_user_agent')
        expect(response.body).not_to include('expected_remote_host')
        expect(response.body).not_to include('expected_remote_addr')
        expect(response.body).not_to include('expected_remote_user')
        expect(response.body).not_to include('expected_x_forwarded_for')
        expect(response.body).to include('(none)')
      end
    end
  end

  describe "GET /status" do
    let(:solr_url) { YAML.load(ERB.new(File.read(Rails.root.join('config', 'solr.yml'))).result)[Rails.env]['url'].sub('/solr/', '/solr/admin/cores?action=STATUS&core=') }
    let(:fedora_url) { YAML.load(ERB.new(File.read(Rails.root.join('config', 'fedora.yml'))).result)[Rails.env]['url'] }
    let(:platform_admin) { create(:platform_admin) }

    context 'all good' do
      before do
        # Many of these would pass without stubbing in tests: fedora, solr, ps etc. But definitely don't want to call...
        # out to Shib, or have tests depend on redis running to pass. As it's mock em all or mock some and have...
        # some sort of added complexity for others ()that also use Kernel system calls), I'll mock em all.
        allow_any_instance_of(Kernel).to receive(:`).with('redis-cli ping').and_return("PONG\n")
        allow_any_instance_of(Kernel).to receive(:`).with('uptime').and_return("15:44  up 9 days,  1:06, 21 users, load averages: 2.98 3.41 3.23")
        allow_any_instance_of(Kernel).to receive(:`).with("curl --max-time 5 -s -w \"%{http_code}\" '#{solr_url}'").and_return("blah... <str name=\"instanceDir\">/path/to/solr/core/dir</str>...blah\n200")
        allow_any_instance_of(Kernel).to receive(:`).with("curl --max-time 5 -s -o /dev/null -w \"%{http_code}\" '#{fedora_url}'").and_return("200")
        allow_any_instance_of(Kernel).to receive(:`).with("ps -f -u $USER").and_return("processy puma stuff line 1\nprocessy resque workers stuff line 2")
        allow_any_instance_of(Kernel).to receive(:`).with("fits.sh -v").and_return("build.version=1.3.0")

        allow(Resque).to receive_message_chain(:workers, :count).and_return(5)
        allow(Resque).to receive_message_chain(:workers, :select).and_return([1, 2, 3])

        # some stuff I'm just going to stub on StatusPageService because what's the difference?
        # the required `Net::HTTP` checks are too egregious to mock and I want to make sure this doesn't hit Shibboleth
        allow_any_instance_of(StatusPageService).to receive(:shib_check_redirecting).and_return('UP')
        # some of these won't exist in test, no point stubbing `File.exist?`, `File.read`, or `YAML.load` here
        allow_any_instance_of(StatusPageService).to receive(:check_config_file).and_return('OK')
      end

      it 'shows non-server info to anonymous users' do
        get status_utility_path
        expect(response).to have_http_status(:success)

        expect(response.body).to include('Redis ................. UP')
        expect(response.body).to include('Resque workers .......... 5 registered, 3 working')
        expect(response.body).to include('MySQL ................. UP')

        expect(response.body).to include('database.yml .......... OK')
        expect(response.body).to include('fedora.yml ............ OK')
        expect(response.body).to include('secrets.yml ........... OK')
        expect(response.body).to include('solr.yml .............. OK')
        expect(response.body).to include('analytics.yml ......... OK')
        expect(response.body).to include('aptrust.yml ........... OK')
        expect(response.body).to include('blacklight.yml ........ OK')
        expect(response.body).to include('box.yml ............... OK')
        expect(response.body).to include('crossref.yml .......... OK')
        expect(response.body).to include('redis.yml ............. OK')
        expect(response.body).to include('resque-pool.yml ....... OK')
        expect(response.body).to include('role_map.yml .......... OK')
        expect(response.body).to include('skylight.yml .......... OK')

        expect(response.body).to include('Fedora ................ UP')
        expect(response.body).to include('Solr .................. UP - core found')
        expect(response.body).to include('Shibboleth ............ UP')

        expect(response.body).to include('FITS .................. build.version=1.3.0')

        expect(response.body).to_not include('Server Uptime')
        expect(response.body).to_not include("15:44  up 9 days,  1:06, 21 users, load averages: 2.98 3.41 3.23")
        expect(response.body).to_not include('Processes - Puma workers')
        expect(response.body).to_not include('processy puma stuff line 1')
        expect(response.body).to_not include('Processes - Resque workers')
        expect(response.body).to_not include('processy resque workers stuff line 2')
      end

      context 'platform admin' do
        before { sign_in platform_admin }

        it 'shows everything' do
          get status_utility_path
          expect(response).to have_http_status(:success)

          expect(response.body).to include('Redis ................. UP')
          expect(response.body).to include('Resque workers .......... 5 registered, 3 working')
          expect(response.body).to include('MySQL ................. UP')

          expect(response.body).to include('database.yml .......... OK')
          expect(response.body).to include('fedora.yml ............ OK')
          expect(response.body).to include('secrets.yml ........... OK')
          expect(response.body).to include('solr.yml .............. OK')
          expect(response.body).to include('analytics.yml ......... OK')
          expect(response.body).to include('aptrust.yml ........... OK')
          expect(response.body).to include('blacklight.yml ........ OK')
          expect(response.body).to include('box.yml ............... OK')
          expect(response.body).to include('crossref.yml .......... OK')
          expect(response.body).to include('redis.yml ............. OK')
          expect(response.body).to include('resque-pool.yml ....... OK')
          expect(response.body).to include('role_map.yml .......... OK')
          expect(response.body).to include('skylight.yml .......... OK')

          expect(response.body).to include('Fedora ................ UP')
          expect(response.body).to include('Solr .................. UP - core found')
          expect(response.body).to include('Shibboleth ............ UP')

          expect(response.body).to include('FITS .................. build.version=1.3.0')


          expect(response.body).to include('Server Uptime')
          expect(response.body).to include("15:44  up 9 days,  1:06, 21 users, load averages: 2.98 3.41 3.23")
          expect(response.body).to include('Processes - Puma workers')
          expect(response.body).to include('processy puma stuff line 1')
          expect(response.body).to include('Processes - Resque workers')
          expect(response.body).to include('processy resque workers stuff line 2')
        end
      end
    end

    context 'all bad' do
      before do
        allow_any_instance_of(Kernel).to receive(:`).with('redis-cli ping').and_return('')
        allow_any_instance_of(Kernel).to receive(:`).with('uptime').and_return("Server out to lunch!")
        allow(ActiveRecord::Migrator).to receive(:current_version).and_raise("BLAH")
        allow_any_instance_of(Kernel).to receive(:`).with("curl --max-time 5 -s -w \"%{http_code}\" '#{solr_url}'").and_return('404')
        allow_any_instance_of(Kernel).to receive(:`).with("curl --max-time 5 -s -o /dev/null -w \"%{http_code}\" '#{fedora_url}'").and_return('404')
        allow_any_instance_of(Kernel).to receive(:`).with("ps -f -u $USER").and_return("processy stuff line 1\nprocessy stuff line 2")
        allow_any_instance_of(Kernel).to receive(:`).with("fits.sh -v").and_return('')

        allow(Resque).to receive_message_chain(:workers, :count).and_return(0)
        allow(Resque).to receive_message_chain(:workers, :select).and_return([])

        # some stuff I'm just going to stub on StatusPageService because what's the difference?
        # the required `Net::HTTP` checks are too egregious to mock and I want to make sure this doesn't hit Shibboleth
        allow_any_instance_of(StatusPageService).to receive(:shib_check_redirecting).and_return('DOWN')
        # some of these won't exist in test, no point stubbing `File.exist?`, `File.read`, or `YAML.load` here
        allow_any_instance_of(StatusPageService).to receive(:check_config_file).and_return('NOT FOUND')
      end

      it 'shows non-server info to anonymous users' do
        get status_utility_path
        expect(response).to have_http_status(:success)

        expect(response.body).to include('Redis ................. DOWN')
        expect(response.body).to include('Resque workers .......... 0 registered, 0 working')
        expect(response.body).to include('MySQL ................. DOWN')

        expect(response.body).to include('database.yml .......... NOT FOUND')
        expect(response.body).to include('fedora.yml ............ NOT FOUND')
        expect(response.body).to include('secrets.yml ........... NOT FOUND')
        expect(response.body).to include('solr.yml .............. NOT FOUND')
        expect(response.body).to include('analytics.yml ......... NOT FOUND')
        expect(response.body).to include('aptrust.yml ........... NOT FOUND')
        expect(response.body).to include('blacklight.yml ........ NOT FOUND')
        expect(response.body).to include('box.yml ............... NOT FOUND')
        expect(response.body).to include('crossref.yml .......... NOT FOUND')
        expect(response.body).to include('redis.yml ............. NOT FOUND')
        expect(response.body).to include('resque-pool.yml ....... NOT FOUND')
        expect(response.body).to include('role_map.yml .......... NOT FOUND')
        expect(response.body).to include('skylight.yml .......... NOT FOUND')

        expect(response.body).to include('Fedora ................ DOWN')
        expect(response.body).to include('Solr .................. DOWN')
        expect(response.body).to include('Shibboleth ............ DOWN')

        expect(response.body).to include('FITS .................. NOT FOUND')

        expect(response.body).to_not include('Server Uptime')
        expect(response.body).to_not include('Server out to lunch!')
        expect(response.body).to_not include('Processes - Puma workers')
        expect(response.body).to_not include('processy puma stuff line 1')
        expect(response.body).to_not include('Processes - Resque workers')
        expect(response.body).to_not include('processy resque workers stuff line 2')
      end

      context 'platform admin' do
        before { sign_in platform_admin }

        it 'shows everything' do
          get status_utility_path
          expect(response).to have_http_status(:success)

          expect(response.body).to include('Redis ................. DOWN')
          expect(response.body).to include('Resque workers .......... 0 registered, 0 working')
          expect(response.body).to include('MySQL ................. DOWN')

          expect(response.body).to include('database.yml .......... NOT FOUND')
          expect(response.body).to include('fedora.yml ............ NOT FOUND')
          expect(response.body).to include('secrets.yml ........... NOT FOUND')
          expect(response.body).to include('solr.yml .............. NOT FOUND')
          expect(response.body).to include('analytics.yml ......... NOT FOUND')
          expect(response.body).to include('aptrust.yml ........... NOT FOUND')
          expect(response.body).to include('blacklight.yml ........ NOT FOUND')
          expect(response.body).to include('box.yml ............... NOT FOUND')
          expect(response.body).to include('crossref.yml .......... NOT FOUND')
          expect(response.body).to include('redis.yml ............. NOT FOUND')
          expect(response.body).to include('resque-pool.yml ....... NOT FOUND')
          expect(response.body).to include('role_map.yml .......... NOT FOUND')
          expect(response.body).to include('skylight.yml .......... NOT FOUND')

          expect(response.body).to include('Fedora ................ DOWN')
          expect(response.body).to include('Solr .................. DOWN')
          expect(response.body).to include('Shibboleth ............ DOWN')

          expect(response.body).to include('FITS .................. NOT FOUND')

          expect(response.body).to include('Server Uptime')
          expect(response.body).to include('Server out to lunch!')
          expect(response.body).to include('Processes - Puma workers')
          expect(response.body).to_not include('processy puma stuff line 1')
          expect(response.body).to include('Processes - Resque workers')
          expect(response.body).to_not include('processy resque workers stuff line 2')
        end
      end
    end
  end
end
