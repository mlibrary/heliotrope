# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::FileSetsController, type: :controller do
  let(:user) { create(:platform_admin) }
  let(:press) { create(:press) }
  let(:monograph) { create(:monograph, user: user, press: press.subdomain) }
  let(:file_set) { create(:file_set) }

  before do
    monograph.ordered_members << file_set
    monograph.save!
    file_set.save!
    sign_in user
  end

  describe "#show" do
    it 'succeeds' do
      get :show, params: { id: file_set.id }
      expect(response).to have_http_status(:success)
      expect(controller.instance_variable_get(:@auth)).to be_an_instance_of(Auth)
      expect(controller.instance_variable_get(:@auth).return_location).to eq Rails.application.routes.url_helpers.hyrax_file_set_path(file_set)
    end
  end

  describe "#destroy" do
    before { stub_out_redis }

    context "featured_representative file_set and cached table of contents" do
      before do
        FeaturedRepresentative.create(work_id: monograph.id, file_set_id: file_set.id, kind: 'epub')
        EbookTableOfContentsCache.create(noid: file_set.id, toc: [{ title: "A", depth: 1, cfi: "/6/2[Chapter01]!/4/1:0" }].to_json)
      end

      it "deletes the featured_representative and the file_set" do
        expect do
          delete :destroy, params: { id: file_set }
        end.to change { FeaturedRepresentative.all.count }.from(1).to(0)
        expect(EbookTableOfContentsCache.find_by(noid: file_set.id)).to be nil
        expect(FileSet.all.count).to be 0
      end
    end

    context "not a featured_representative and not cached table of contents" do
      it "just deletes the file_set" do
        delete :destroy, params: { id: file_set }
        expect(FileSet.all.count).to be 0
      end
    end
  end

  # Some of the update specs lifted from
  # https://github.com/samvera/hyrax/blob/4c1a99a6a52c973781dff090c2c98c044ea65e42/spec/controllers/hyrax/file_sets_controller_spec.rb#L78
  # with minor changes to get them passing in heliotrope
  describe "#update" do
    let(:parent) { FactoryBot.create(:public_monograph, user: user) }

    let(:file_set) do
      FactoryBot.create(:file_set, user: user, title: ['test title']).tap do |file_set|
        parent.ordered_members << file_set
        parent.save!
      end
    end

    context "when updating metadata" do
      before { ActiveJob::Base.queue_adapter = :test }
      after { ActiveJob::Base.queue_adapter = :resque }

      it "spawns a content update event job" do
        expect do
          post :update, params: {
            id: file_set,
            file_set: {
              title: ['new_title'],
              keyword: [''],
              permissions_attributes: [{ type: 'person',
                                         name: 'archivist1',
                                         access: 'edit' }]
            }
          }
        end.to have_enqueued_job(ContentUpdateEventJob).exactly(:once)

        expect(response)
          .to redirect_to Rails.application.routes.url_helpers.hyrax_file_set_path(file_set, locale: 'en')
        expect(assigns[:file_set].modified_date)
          .not_to be file_set.modified_date
      end
    end

    context "when updating the attached file already uploaded" do
      let(:actor) { double(Hyrax::Actors::FileActor) }

      before do
        allow(Hyrax::Actors::FileActor).to receive(:new).and_return(actor)
      end

      it "spawns a ContentNewVersionEventJob", perform_enqueued: [IngestJob] do
        expect(actor)
          .to receive(:ingest_file)
          .with(JobIoWrapper)
          .and_return(true)
        expect(ContentNewVersionEventJob)
          .to receive(:perform_later)
          .with(file_set, user)

        file = fixture_file_upload('/lorum_ipsum_toc_cover.png', 'image/png')
        allow(Hyrax::UploadedFile)
          .to receive(:find)
          .with(["1"])
          .and_return([file])

        post :update, params: { id: file_set, files_files: ["1"] }

        expect(assigns[:file_set].modified_date)
          .not_to be file_set.modified_date
        expect(assigns[:file_set].title)
          .to contain_exactly(*file_set.title)
      end
    end

    context "with two existing versions from different users", :perform_enqueued do
      let(:file1)       { "lorum_ipsum_toc_cover.png" }
      let(:file2)       { "kitty.tif" }
      let(:second_user) { create(:user) }
      let(:version1)    { "version1" }
      # let(:actor1)      { Hyrax::Actors::FileSetActor.new(file_set, user) }
      # let(:actor2)      { Hyrax::Actors::FileSetActor.new(file_set, second_user) }

      before do
        # ActiveJob::Base.queue_adapter.filter = [IngestJob]
        # actor1.create_content(fixture_file_upload(file1))
        # actor2.create_content(fixture_file_upload(file2))
        Hydra::Works::AddFileToFileSet.call(file_set, File.open(fixture_path + "/#{file1}"), :original_file)
        Hydra::Works::AddFileToFileSet.call(file_set, File.open(fixture_path + "/#{file2}"), :original_file)
      end

      describe "restoring a previous version" do
        context "as the first user" do
          before do
            ActiveJob::Base.queue_adapter = :test
            sign_in user
            post :update, params: { id: file_set, revision: version1 }
          end
          after { ActiveJob::Base.queue_adapter = :resque }

          let(:restored_content) { file_set.reload.original_file }
          let(:versions)         { restored_content.versions }
          let(:latest_version)   { Hyrax::VersioningService.latest_version_of(restored_content) }

          it "restores the first versions's content and metadata" do
            # expect(restored_content.mime_type).to eq "image/png"
            expect(restored_content).to be_a(Hydra::PCDM::File)
            expect(restored_content.original_name).to eq file1
            expect(versions.all.count).to eq 3
            expect(versions.last.label).to eq latest_version.label
            expect(Hyrax::VersionCommitter.where(version_id: versions.last.uri).pluck(:committer_login))
              .to eq [user.user_key]
          end
        end

        context "as a user without edit access" do
          before { sign_in second_user }

          it "is unauthorized" do
            post :update, params: { id: file_set, revision: version1 }
            expect(response.code).to eq '401'
            expect(response).to render_template 'unauthorized'
            expect(response).to render_template('dashboard')
          end
        end
      end
    end

    it "adds new groups and users" do
      post :update, params: {
        id: file_set,
        file_set: { keyword: [''],
                    permissions_attributes: [
                      { type: 'person', name: 'user1', access: 'edit' },
                      { type: 'group', name: 'group1', access: 'read' }
                    ] }
      }

      expect(assigns[:file_set])
        .to have_attributes(read_groups: contain_exactly("group1"),
                            edit_users: include("user1", user.user_key))
    end

    it "updates existing groups and users" do
      file_set.edit_groups = ['group3']
      file_set.save

      post :update, params: {
        id: file_set,
        file_set: { keyword: [''],
                    permissions_attributes: [
                      { id: file_set.permissions.last.id, type: 'group', name: 'group3', access: 'read' }
                    ] }
      }

      expect(assigns[:file_set].read_groups).to contain_exactly("group3")
    end

    context "when there's an error saving" do
      let(:parent) { FactoryBot.create(:public_monograph, user: user) }

      let(:file_set) do
        FactoryBot.create(:file_set, user: user).tap do |file_set|
          parent.ordered_members << file_set
          parent.save!
        end
      end

      before { allow(FileSet).to receive(:find).and_return(file_set) }

      it "draws the edit page" do
        expect(file_set).to receive(:valid?).and_return(false)
        post :update, params: { id: file_set, file_set: { keyword: [''] } }
        expect(response.code).to eq '422'
        expect(response).to render_template('edit')
        expect(response).to render_template('dashboard')
        expect(assigns[:file_set]).to eq file_set
      end
    end
  end

  context 'tombstone' do
    context 'file set created' do
      before do
        get :show, params: { parent_id: monograph.id, id: file_set.id }
      end

      it do
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
        expect(response).to render_template("hyrax/file_sets/show")
      end
    end

    context 'file set deleted' do
      before do
        file_set.destroy!
        get :show, params: { parent_id: monograph.id, id: file_set.id }
      end

      it do
        # The HTTP response status code 302 Found is a common way of performing URL redirection.
        expect(response).to have_http_status(:found)
        # raise CanCan::AccessDenied currently redirects to root_url
        expect(response.header["Location"]).to match "http://test.host/"
      end
    end
  end

  context 'redirection with redirect_to' do
    context 'orphan FileSet redirects to FileSet with monograph parent' do
      let(:orphan_file_set) { create(:file_set, redirect_to: file_set.id) }

      it 'redirects to the appropriate file_set in redirect_to' do
        get :show, params: { id: orphan_file_set.id }
        expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_file_set_path(file_set.id)
      end
    end

    context 'redirect_to doesn\'t contain a FileSet NOID' do
      let(:root_redirect_fileset) { create(:file_set, redirect_to: 'home page') }

      it 'redirects to root' do
        get :show, params: { id: root_redirect_fileset.id }
        expect(response).to redirect_to '/'
      end
    end
  end

  context 'redirection of non-editors from cover/representative file_set show pages' do
    let(:epub_monograph) {
      create(:public_monograph,
             user: user,
             press: press.subdomain,
             representative_id: cover.id,
             thumbnail_id: thumbnail.id)
    }
    let(:epub) { create(:public_file_set) }
    let(:cover) { create(:public_file_set) }
    let(:thumbnail) { create(:public_file_set) }
    let(:fre) { create(:featured_representative, work_id: epub_monograph.id, file_set_id: epub.id, kind: 'epub') }

    before do
      epub_monograph.ordered_members = [cover, thumbnail, epub]
      epub_monograph.save!
      [cover, thumbnail, epub].map(&:save!)
    end

    context 'editor tries to load show page of a cover/representative file_set' do
      it 'representative loads its show page' do
        get :show, params: { id: fre.file_set_id }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
        expect(response).to render_template("hyrax/file_sets/show")
      end

      it 'cover loads its show page' do
        get :show, params: { id: cover.id }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
        expect(response).to render_template("hyrax/file_sets/show")
      end

      it 'thumbnail loads its show page' do
        get :show, params: { id: thumbnail.id }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
        expect(response).to render_template("hyrax/file_sets/show")
      end
    end

    context 'non-editor tries to load show page of a cover/representative file_set' do
      let(:non_editor) { create(:user) }

      before do
        sign_in non_editor
      end

      it 'representative redirects to the monograph show page' do
        get :show, params: { id: fre.file_set_id }
        expect(response).to redirect_to Rails.application.routes.url_helpers.monograph_catalog_path(epub_monograph.id)
      end

      it 'cover redirects to the monograph show page' do
        get :show, params: { id: cover.id }
        expect(response).to redirect_to Rails.application.routes.url_helpers.monograph_catalog_path(epub_monograph.id)
      end

      it 'thumbnail redirects to the monograph show page' do
        get :show, params: { id: thumbnail.id }
        expect(response).to redirect_to Rails.application.routes.url_helpers.monograph_catalog_path(epub_monograph.id)
      end
    end
  end

  context 'update the thumbnail' do
    let(:thumbnail_path) { File.join(fixture_path, 'csv', 'shipwreck.jpg') }
    let(:thumbnail_deriv_path) { Hyrax::DerivativePath.derivative_path_for_reference(file_set.id, 'thumbnail') }
    let(:file) { fixture_file_upload('/csv/shipwreck.jpg', 'image/jpg') }

    it 'copies the updated file to the thumbnail derivative path' do
      # no derivatives for this FileSet yet
      expect(Hyrax::DerivativePath.derivatives_for_reference(file_set).count).to eq 0
      expect(File).not_to exist(thumbnail_deriv_path)

      post :update, params: { id: file_set, user_thumbnail: { custom_thumbnail: file } }

      # now the "uploaded" thumbnail is in place
      expect(Hyrax::DerivativePath.derivatives_for_reference(file_set).count).to eq 1
      expect(File).to exist(thumbnail_deriv_path)
      expect(FileUtils.compare_file(thumbnail_path, thumbnail_deriv_path)).to be_truthy
    end
    after do
      FileUtils.rm_rf(Hyrax.config.derivatives_path)
    end
  end

  context 'setting the `thumbnail_path_ss` Solr value' do
    # note: querying the changed Solr values results in intermittent timing errors, so just verifying SolrService.add()
    let(:file_set_doc_default) { file_set.to_solr.merge(thumbnail_path_ss: default_thumbnail_path) }
    let(:default_thumbnail_path) { ActionController::Base.helpers.image_path('default.png') }

    let(:file_set_doc_derivative) { file_set.to_solr.merge(thumbnail_path_ss: thumbnail_derivative_path) }
    let(:thumbnail_derivative_path) { Hyrax::Engine.routes.url_helpers.download_path(file_set.id, file: 'thumbnail') }

    it 'sets it to the Hyrax default thumbnail path' do
      expect(ActiveFedora::SolrService).to receive(:add).with(file_set_doc_default, softCommit: true)
      post :update, params: { id: file_set, user_thumbnail: { use_default: '1' } }
    end
    it 'sets it to the thumbnail derivative path' do
      expect(ActiveFedora::SolrService).to receive(:add).with(file_set_doc_derivative, softCommit: true)
      post :update, params: { id: file_set, user_thumbnail: { use_default: '0' } }
    end
  end

  context "counter report counts from the show page" do
    let(:keycard) { { dlpsInstitutionId: [dlps_institution_id.to_s] } }
    let(:institution) { create(:institution, identifier: dlps_institution_id.to_s) }
    let(:institution_affiliation) { create(:institution_affiliation, institution: institution, dlps_institution_id: dlps_institution_id, affiliation: 'member') }
    let(:dlps_institution_id) { 9999 }

    before do
      institution_affiliation
      allow_any_instance_of(Keycard::Request::Attributes).to receive(:all).and_return(keycard)
      file_set.read_groups << "public"
      file_set.visibility = "open"
    end

    context "a multimedia file_set" do
      before do
        Hydra::Works::AddFileToFileSet.call(file_set, File.open(fixture_path + '/csv/shipwreck.jpg'), :original_file)
        file_set.save!
      end

      it "counts as an investigation and a request" do
        get :show, params: { id: file_set.id }
        cr = CounterReport.last
        expect(cr.request).to eq 1
        expect(cr.investigation).to eq 1
      end
    end

    context "a non-multimedia file_set" do
      before do
        Hydra::Works::AddFileToFileSet.call(file_set, File.open(fixture_path + '/stuff.xlsx'), :original_file)
        file_set.save!
      end

      it "counts only as an investigation" do
        get :show, params: { id: file_set.id }
        cr = CounterReport.last
        expect(cr.request).to eq nil
        expect(cr.investigation).to eq 1
      end
    end
  end
end
