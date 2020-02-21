# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax do
  describe '#from_noid' do
    subject { described_class.from_noid(noid) }

    let(:noid) { 'validnoid' }

    it 'null_entity' do
      is_expected.to be_an_instance_of(Sighrax::NullEntity)
      expect(subject.noid).to be noid
      expect(subject.send(:data)).to be_empty
    end

    context 'standard error' do
      before { allow(ActiveFedora::SolrService).to receive(:query).with("{!terms f=id}#{noid}", rows: 1).and_raise(StandardError) }

      it 'null_entity' do
        is_expected.to be_an_instance_of(Sighrax::NullEntity)
        expect(subject.noid).to be noid
        expect(subject.send(:data)).to be_empty
      end
    end

    context 'solr document' do
      let(:document) { instance_double(SolrDocument, 'document') }
      let(:entity) { instance_double(Sighrax::Entity, 'entity') }

      before do
        allow(ActiveFedora::SolrService).to receive(:query).with("{!terms f=id}#{noid}", rows: 1).and_return([document])
        allow(described_class).to receive(:from_solr_document).with(document).and_return(entity)
      end

      it 'from_solr_document' do
        is_expected.to be entity
        expect(described_class).to have_received(:from_solr_document).with(document)
      end
    end
  end

  describe '#from_presenter' do
    subject { described_class.from_presenter(presenter) }

    let(:presenter) { double('presenter') }
    let(:document) { instance_double(SolrDocument, 'document') }
    let(:entity) { instance_double(Sighrax::Entity, 'entity') }

    before do
      allow(presenter).to receive(:solr_document).and_return(document)
      allow(described_class).to receive(:from_solr_document).with(document).and_return(entity)
    end

    it 'from_solr_document' do
      is_expected.to be entity
      expect(described_class).to have_received(:from_solr_document).with(document)
    end
  end

  describe '#from_solr_document' do
    subject { described_class.from_solr_document(document) }

    let(:document) { }

    it { is_expected.to be_an_instance_of(Sighrax::NullEntity) }
    it { expect(subject.noid).to be nil }
    it { expect(subject.send(:data)).to be_empty }

    context 'NullEntity' do
      let(:document) { ::SolrDocument.new(id: 'invalidnoid') }

      it { is_expected.to be_an_instance_of(Sighrax::NullEntity) }
      it { expect(subject.noid).to eq(document.id) }
      it { expect(subject.send(:data)).to be_empty }
    end

    context 'Entity' do
      let(:document) { ::SolrDocument.new(id: 'validnoid') }

      it { is_expected.to be_an_instance_of(Sighrax::Entity) }
      it { expect(subject.noid).to eq(document.id) }
      it { expect(subject.send(:data)).to eq(document.to_h.with_indifferent_access) }

      context 'Model' do
        let(:document) { ::SolrDocument.new(id: 'validnoid', has_model_ssim: [model_type]) }
        let(:model_type) { 'unknown' }

        it { is_expected.to be_an_instance_of(Sighrax::Model) }

        context 'Monograph' do
          let(:model_type) { 'Monograph' }

          it { is_expected.to be_an_instance_of(Sighrax::Monograph) }
        end

        context 'Score' do
          let(:model_type) { 'Score' }

          it { is_expected.to be_an_instance_of(Sighrax::Score) }
        end

        context 'Asset' do
          let(:model_type) { 'FileSet' }
          let(:featured_representatitve) { }

          before do
            allow(FeaturedRepresentative).to receive(:find_by).with(file_set_id: document['id']).and_return(featured_representatitve)
          end

          it { is_expected.to be_an_instance_of(Sighrax::Asset) }

          context 'FeaturedRepresentative' do
            let(:featured_representatitve) { double('featured_representatitve', kind: kind) }
            let(:kind) { 'unknown' }

            it { is_expected.to be_an_instance_of(Sighrax::Asset) }

            context 'ElectronicPublication' do
              let(:kind) { 'epub' }

              it { is_expected.to be_an_instance_of(Sighrax::ElectronicPublication) }
            end

            context 'Mobipocket' do
              let(:kind) { 'mobi' }

              it { is_expected.to be_an_instance_of(Sighrax::Mobipocket) }
            end

            context 'PortableDocumentFormat' do
              let(:kind) { 'pdf_ebook' }

              it { is_expected.to be_an_instance_of(Sighrax::PortableDocumentFormat) }
            end
          end
        end
      end
    end
  end

  describe '#policy' do
    subject { described_class.policy(actor, entity) }

    let(:actor) { double('actor') }
    let(:entity) { described_class.from_noid(noid) }
    let(:noid) { 'validnoid' }
    let(:data) { {} }

    it { is_expected.to be_an_instance_of(EntityPolicy) }
  end

  describe '#press' do
    subject { described_class.press(entity) }

    let(:entity) { described_class.from_noid(noid) }
    let(:noid) { 'validnoid' }
    let(:data) { {} }

    it { is_expected.to be_an_instance_of(NullPress) }

    context 'Entity' do
      let(:data) { ::SolrDocument.new(id: noid) }

      before { allow(ActiveFedora::SolrService).to receive(:query).with("{!terms f=id}#{noid}", rows: 1).and_return([data]) }

      it { is_expected.to be_an_instance_of(NullPress) }
    end

    context 'Monograph with FileSet' do
      let(:noid) { monograph.id }
      let(:monograph) do
        create(:public_monograph, press: press.subdomain) do |m|
          m.ordered_members << file_set
          m.save!
          file_set.save!
          m
        end
      end
      let(:press) { create(:press) }
      let(:file_set) { create(:public_file_set) }

      it { is_expected.to be_an_instance_of(Press) }
      it { expect(subject.subdomain).to eq(press.subdomain) }

      context 'Orphan FileSet' do
        let(:noid) { file_set.id }

        it { is_expected.to be_an_instance_of(NullPress) }

        context 'Monograph FileSet' do
          before { monograph }

          it { is_expected.to be_an_instance_of(Press) }
          it { expect(subject.subdomain).to eq(press.subdomain) }
        end
      end
    end
  end

  describe '#hyrax_presenter' do
    subject { described_class.hyrax_presenter(entity) }

    let(:entity) { described_class.from_noid(noid) }
    let(:noid) { 'validnoid' }
    let(:data) { {} }

    it { is_expected.to be_an_instance_of(Hyrax::Presenter) }

    context 'Entity' do
      let(:data) { ::SolrDocument.new(id: noid) }

      before { allow(ActiveFedora::SolrService).to receive(:query).with("{!terms f=id}#{noid}", rows: 1).and_return([data]) }

      it { is_expected.to be_an_instance_of(Hyrax::Presenter) }
    end

    context 'Monograph' do
      let(:noid) { monograph.id }
      let(:monograph) { create(:public_monograph) }

      it { is_expected.to be_an_instance_of(Hyrax::MonographPresenter) }
    end

    context 'Score' do
      let(:noid) { score.id }
      let(:score) { create(:public_score) }

      it { is_expected.to be_an_instance_of(Hyrax::ScorePresenter) }
    end

    context 'Asset' do
      let(:noid) { file_set.id }
      let(:file_set) { create(:public_file_set) }

      it { is_expected.to be_an_instance_of(Hyrax::FileSetPresenter) }
    end
  end

  context 'Checkpoint Helpers' do
    describe '#access?' do
      subject { described_class.access?(actor, target) }

      let(:actor) { double('actor') }
      let(:target) { double('target', noid: noid) }
      let(:noid) { double('noid') }
      let(:component) { double('component', products: [component_product]) }
      let(:component_product) { double('component_product') }
      let(:greensub_product) { double('greensub_product') }
      let(:sudo_actor) { false }
      let(:incognito_product) { double('incognito_product') }

      before do
        allow(Greensub::Component).to receive(:find_by).with(noid: noid).and_return(component)
        allow(Greensub).to receive(:actor_products).with(actor).and_return([greensub_product])
        allow(Incognito).to receive(:sudo_actor?).with(actor).and_return(sudo_actor)
        allow(Incognito).to receive(:sudo_actor_products).with(actor).and_return([incognito_product])
      end

      it { is_expected.to be false }

      context 'product intersection' do
        let(:product) { double('product') }
        let(:greensub_product) { product }
        let(:component_product) { product }

        it { is_expected.to be true }

        context 'incognito' do
          let(:sudo_actor) { true }

          it { is_expected.to be false }

          context 'product intersection' do
            let(:incognito_product) { product }

            it { is_expected.to be true }
          end
        end
      end
    end

    describe '#hyrax_can?' do
      subject { described_class.hyrax_can?(actor, action, target) }

      let(:actor) { double('actor', is_a?: anonymous) }
      let(:anonymous) { false }
      let(:action) { :action }
      let(:target) { double('target', valid?: valid, noid: 'noid') }
      let(:valid) { true }
      let(:allow_hyrax_can) { true }
      let(:ability) { double('ability') }
      let(:can) { true }

      before do
        allow(Incognito).to receive(:allow_hyrax_can?).with(actor).and_return(allow_hyrax_can)
        allow(Ability).to receive(:new).with(actor).and_return(ability)
        allow(ability).to receive(:can?).with(action, target.noid).and_return(can)
      end

      context 'user can' do
        it { is_expected.to be true }

        context 'anonymous' do
          let(:anonymous) { true }

          it { is_expected.to be false }
        end

        context 'invalid action' do
          let(:action) { 'action' }

          it { is_expected.to be false }
        end

        context 'invalid target' do
          let(:valid) { false }

          it { is_expected.to be false }
        end

        context 'do not allow hyrax_can' do
          let(:allow_hyrax_can) { false }

          it { is_expected.to be false }
        end

        context 'can not' do
          let(:can) { false }

          it { is_expected.to be false }
        end
      end
    end
  end

  context 'Role Helpers' do
    describe '#platform_admin?' do
      subject { described_class.platform_admin?(actor) }

      let(:actor) { double('actor') }
      let(:user) { false }
      let(:platform_admin) { false }
      let(:allow_platform_admin) { true }

      before do
        allow(actor).to receive(:is_a?).with(User).and_return(user)
        allow(actor).to receive(:platform_admin?).and_return(platform_admin)
        allow(Incognito).to receive(:allow_platform_admin?).with(actor).and_return(allow_platform_admin)
      end

      it { is_expected.to be false }

      context 'user' do
        let(:user) { true }

        it { is_expected.to be false }

        context 'platform_admin' do
          let(:platform_admin) { true }

          it { is_expected.to be true }

          context 'incognito' do
            let(:allow_platform_admin) { false }

            it { is_expected.to be false }
          end
        end
      end
    end

    describe '#press_admin?' do
      subject { described_class.press_admin?(actor, press) }

      let(:actor) { double('actor') }
      let(:press) { instance_double(Press, 'press') }
      let(:user) { false }
      let(:admins) { instance_double(ActiveRecord::Relation, 'admins') }
      let(:press_admins) { instance_double(ActiveRecord::Relation, 'press_admins') }
      let(:any_press_admins) { false }

      before do
        allow(actor).to receive(:is_a?).with(User).and_return(user)
        allow(actor).to receive(:admin_roles).and_return(admins)
        allow(admins).to receive(:where).with(resource: press).and_return(press_admins)
        allow(press_admins).to receive(:any?).and_return(any_press_admins)
      end

      it { is_expected.to be false }

      context 'user' do
        let(:user) { true }

        it { is_expected.to be false }

        context 'press_admin' do
          let(:any_press_admins) { true }

          it { is_expected.to be true }
        end
      end
    end

    describe '#press_editor?' do
      subject { described_class.press_editor?(actor, press) }

      let(:actor) { double('actor') }
      let(:press) { instance_double(Press, 'press') }
      let(:user) { false }
      let(:editors) { instance_double(ActiveRecord::Relation, 'editors') }
      let(:press_editors) { instance_double(ActiveRecord::Relation, 'press_editors') }
      let(:any_press_editors) { false }

      before do
        allow(actor).to receive(:is_a?).with(User).and_return(user)
        allow(actor).to receive(:editor_roles).and_return(editors)
        allow(editors).to receive(:where).with(resource: press).and_return(press_editors)
        allow(press_editors).to receive(:any?).and_return(any_press_editors)
      end

      it { is_expected.to be false }

      context 'user' do
        let(:user) { true }

        it { is_expected.to be false }

        context 'press_editor' do
          let(:any_press_editors) { true }

          it { is_expected.to be true }
        end
      end
    end
  end

  context 'Entity Helpers' do
    let(:entity) { described_class.from_noid(noid) }
    let(:noid) { 'validnoid' }
    let(:data) { {} }

    before { allow(ActiveFedora::SolrService).to receive(:query).with("{!terms f=id}#{noid}", rows: 1).and_return([data]) }

    describe '#allow_download?' do
      subject { described_class.allow_download?(entity) }

      it { is_expected.to be false }

      context 'Entity' do
        let(:data) { ::SolrDocument.new(id: noid, 'allow_download_ssim' => ['yes']) }
        let(:downloadable) { true }

        before { allow(described_class).to receive(:downloadable?).with(entity).and_return(downloadable) }

        it { is_expected.to be true }

        context 'do not allow download' do
          let(:data) { ::SolrDocument.new(id: noid, 'allow_download_ssim' => ['anything but yes']) }

          it { is_expected.to be false }
        end

        context 'non downloadable' do
          let(:downloadable) { false }

          it { is_expected.to be false }
        end
      end
    end

    describe '#deposited?' do
      subject { described_class.deposited?(entity) }

      it { is_expected.to be false }

      context 'Entity' do
        let(:data) { ::SolrDocument.new(id: noid) }

        it { is_expected.to be true }

        context "'suppressed_bsi' => false" do
          let(:data) { ::SolrDocument.new(id: noid, 'suppressed_bsi' => false) }

          it { is_expected.to be true }
        end

        context "'suppressed_bsi' => true" do
          let(:data) { ::SolrDocument.new(id: noid, 'suppressed_bsi' => true) }

          it { is_expected.to be false }
        end
      end
    end

    describe '#downloadable?' do
      subject { described_class.downloadable?(entity) }

      it { is_expected.to be false }

      context 'Entity' do
        let(:data) { ::SolrDocument.new(id: noid) }

        it { is_expected.to be false }

        context 'Asset' do
          let(:asset) { true }

          before { allow(entity).to receive(:is_a?).with(Sighrax::Asset).and_return(asset) }

          it { is_expected.to be true }

          context 'external resource url' do
            let(:data) { ::SolrDocument.new(id: noid, 'external_resource_url_ssim' => url) }
            let(:url) { 'url' }

            it { is_expected.to be false }

            context 'blank url' do
              let(:url) { '' }

              it { is_expected.to be true }
            end
          end
        end
      end
    end

    describe '#open_access?' do
      subject { described_class.open_access?(entity) }

      it { is_expected.to be false }

      context 'Entity' do
        let(:data) { ::SolrDocument.new(id: noid) }

        it { is_expected.to be false }

        context "'open_access_tesim' => ''" do
          let(:data) { ::SolrDocument.new(id: noid, 'open_access_tesim' => ['anything but yes']) }

          it { is_expected.to be false }
        end

        context "'open_access_tesim' => 'yes'" do
          let(:data) { ::SolrDocument.new(id: noid, 'open_access_tesim' => ['yes']) }

          it { is_expected.to be true }
        end
      end
    end

    describe '#published?' do
      subject { described_class.published?(entity) }

      it { is_expected.to be false }

      context 'Entity' do
        let(:data) { ::SolrDocument.new(id: noid) }

        it { is_expected.to be false }

        context "'visibility_ssi' => 'restricted'" do
          let(:data) { ::SolrDocument.new(id: noid, 'visibility_ssi' => 'restricted') }

          it { is_expected.to be false }
        end

        context "'visibility_ssi' => 'open'" do
          let(:data) { ::SolrDocument.new(id: noid, 'visibility_ssi' => 'open') }

          it { is_expected.to be true }

          context "'suppressed_bsi' => true" do
            let(:data) { ::SolrDocument.new(id: noid, 'visibility_ssi' => 'open', 'suppressed_bsi' => true) }

            it { is_expected.to be false }
          end
        end
      end
    end

    describe '#restricted?' do
      subject { described_class.restricted?(entity) }

      it { is_expected.to be true }

      context 'Entity' do
        let(:data) { ::SolrDocument.new(id: noid) }

        context 'Component' do
          let(:component) { double('component') }

          before do
            allow(Greensub::Component).to receive(:find_by).with(noid: entity.noid).and_return(component)
          end

          it { is_expected.to be true }
        end
      end
    end

    describe '#tombstone?' do
      subject { described_class.tombstone?(entity) }

      it { is_expected.to be false }

      context 'Entity' do
        let(:data) { ::SolrDocument.new(id: noid) }

        it { is_expected.to be false }

        context 'yesterday' do
          let(:data) { ::SolrDocument.new(id: noid, "permissions_expiration_date_ssim" => (Time.now.utc.to_date - 1).to_s) }

          it { is_expected.to be true }
        end

        context 'today' do
          let(:data) { ::SolrDocument.new(id: noid,  "permissions_expiration_date_ssim" => Time.now.utc.to_date.to_s) }

          it { is_expected.to be true }
        end

        context 'tomorrow' do
          let(:data) { ::SolrDocument.new(id: noid,  "permissions_expiration_date_ssim" => (Time.now.utc.to_date + 1).to_s) }

          it { is_expected.to be false }
        end
      end
    end

    describe '#watermarkable?' do
      subject { described_class.watermarkable?(entity) }

      before { allow(entity).to receive(:is_a?).and_return(false) }

      it { is_expected.to be false }

      context 'Entity' do
        let(:data) { ::SolrDocument.new(id: noid) }

        it { is_expected.to be false }

        context 'Asset' do
          before { allow(entity).to receive(:is_a?).with(Sighrax::Asset).and_return(true) }

          it { is_expected.to be false }

          context 'Portable Document Format' do
            before { allow(entity).to receive(:is_a?).with(Sighrax::PortableDocumentFormat).and_return(true) }

            it { is_expected.to be true }

            context 'external resource url' do
              let(:data) { ::SolrDocument.new(id: noid, 'external_resource_url_ssim' => url) }
              let(:url) { 'url' }

              it { is_expected.to be false }

              context 'blank url' do
                let(:url) { '' }

                it { is_expected.to be true }
              end
            end
          end
        end
      end
    end
  end
end
