# frozen_string_literal: true

RSpec.describe Blacklight::AccessControls::Catalog do
  let(:controller) { CatalogController.new }

  describe '#enforce_show_permissions' do
    subject { controller.enforce_show_permissions }

    let(:params) { { id: doc.id } }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:params).and_return(params)
    end

    context 'when user is not logged in' do
      let(:doc) { create_solr_doc(id: '123') }
      let(:user) { User.new }

      it 'denies access' do
        expect { subject }.to raise_error(Blacklight::AccessControls::AccessDenied)
      end
    end

    context 'when user has access' do
      let(:doc) { create_solr_doc(id: '123', read_access_person_ssim: user.email) }
      let(:user) { build(:user) }

      it 'allows access' do
        expect { subject }.not_to raise_error
      end

      # So that you can override enforce_show_permissions
      # to call "super" and then add more permissions checks
      # after that without having to re-fetch the document.
      it 'returns the permissions doc' do
        expect(subject).to be_a(SolrDocument)
      end
    end
  end

  describe '#search_builder' do
    subject { controller.search_builder }

    before do
      allow(controller).to receive(:current_ability).and_return(instance_double(Ability))
    end

    it 'creates a search_builder' do
      expect(subject).to be_kind_of Blacklight::AccessControls::SearchBuilder
    end
  end
end
