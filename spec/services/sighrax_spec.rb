# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax do
  context 'Factories' do
    describe '#from_noid' do
      subject { described_class.from_noid(noid) }

      let(:noid) { }

      it { is_expected.to eq Sighrax::Entity.null_entity }

      context 'noid' do
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
    end

    describe '#from_presenter' do
      subject { described_class.from_presenter(presenter) }

      let(:presenter) { }

      it { is_expected.to eq Sighrax::Entity.null_entity }

      context 'presenter' do
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
    end

    describe '#from_solr_document' do
      subject { described_class.from_solr_document(document) }

      let(:document) { }

      it { is_expected.to eq Sighrax::Entity.null_entity }

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

          context 'Resource' do
            let(:document) { ::SolrDocument.new(id: 'validnoid', has_model_ssim: [model_type], resource_type_tesim: [resource_type]) }
            let(:model_type) { 'FileSet' }
            let(:resource_type) { }
            let(:featured_representatitve) { }

            before { allow(FeaturedRepresentative).to receive(:find_by).with(file_set_id: document['id']).and_return(featured_representatitve) }

            it { is_expected.to be_an_instance_of(Sighrax::Resource) }

            context 'ResourceTypes' do
              let(:resource_type) { 'unknown' }

              it { is_expected.to be_an_instance_of(Sighrax::Resource) }

              context 'interactive map' do
                let(:resource_type) { 'interactive map' }

                it { is_expected.to be_an_instance_of(Sighrax::InteractiveMap) }

                context 'FeaturedRepresentative' do
                  let(:featured_representatitve) { double('featured_representatitve', kind: kind) }
                  let(:kind) { 'unknown' }

                  it { is_expected.to be_an_instance_of(Sighrax::Resource) }
                end
              end
            end

            context 'FeaturedRepresentative' do
              let(:featured_representatitve) { double('featured_representatitve', kind: kind) }
              let(:kind) { 'unknown' }

              it { is_expected.to be_an_instance_of(Sighrax::Resource) }

              context 'EpubEbook' do
                let(:kind) { 'epub' }

                it { is_expected.to be_an_instance_of(Sighrax::EpubEbook) }
              end

              context 'MobiEbook' do
                let(:kind) { 'mobi' }

                it { is_expected.to be_an_instance_of(Sighrax::MobiEbook) }
              end

              context 'PdfEbook' do
                let(:kind) { 'pdf_ebook' }

                it { is_expected.to be_an_instance_of(Sighrax::PdfEbook) }
              end
            end
          end
        end
      end
    end
  end

  context 'Greensub Helpers' do
    describe '#allow_read_products' do
      subject { described_class.allow_read_products }

      it { is_expected.to be_empty }

      context 'world institution' do
        let(:world_institution) { instance_double(Greensub::Institution, 'world institution', products: products) }
        let(:products) { instance_double(Array, 'products') }

        before { allow(Greensub::Institution).to receive(:find_by).with(identifier: Settings.world_institution_identifier).and_return world_institution }

        it { is_expected.to be products }
      end
    end

    describe '#actor_products' do
      subject { described_class.actor_products(actor) }

      let(:actor) { instance_double(Anonymous, 'actor') }
      let(:products) { instance_double(Array, 'products') }

      before { allow(Greensub).to receive(:actor_products).with(actor).and_return(products) }

      it { is_expected.to be(products) }

      context 'Incognito' do
        let(:incognito_products) { instance_double(Array, 'incognito_products') }

        before do
          allow(Incognito).to receive(:sudo_actor?).with(actor).and_return(true)
          allow(Incognito).to receive(:sudo_actor_products).with(actor).and_return(incognito_products)
        end

        it { is_expected.to be(incognito_products) }
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

    describe '#press_role?' do
      subject { described_class.press_role?(actor, press) }

      let(:actor) { double('actor') }
      let(:press) { instance_double(Press, 'press') }
      let(:user) { false }
      let(:roles) { instance_double(ActiveRecord::Relation, 'roles') }
      let(:press_roles) { instance_double(ActiveRecord::Relation, 'press_admins') }
      let(:any_press_role) { false }

      before do
        allow(actor).to receive(:is_a?).with(User).and_return(user)
        allow(actor).to receive(:press_roles).and_return(roles)
        allow(roles).to receive(:where).with(resource: press).and_return(press_roles)
        allow(press_roles).to receive(:any?).and_return(any_press_role)
      end

      it { is_expected.to be false }

      context 'user' do
        let(:user) { true }

        it { is_expected.to be false }

        context 'press_role' do
          let(:any_press_role) { true }

          it { is_expected.to be true }
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

    describe '#press_analyst?' do
      subject { described_class.press_analyst?(actor, press) }

      let(:actor) { double('actor') }
      let(:press) { instance_double(Press, 'press') }
      let(:user) { false }
      let(:analysts) { instance_double(ActiveRecord::Relation, 'analysts') }
      let(:press_analysts) { instance_double(ActiveRecord::Relation, 'press_analysts') }
      let(:any_press_analysts) { false }

      before do
        allow(actor).to receive(:is_a?).with(User).and_return(user)
        allow(actor).to receive(:analyst_roles).and_return(analysts)
        allow(analysts).to receive(:where).with(resource: press).and_return(press_analysts)
        allow(press_analysts).to receive(:any?).and_return(any_press_analysts)
      end

      it { is_expected.to be false }

      context 'user' do
        let(:user) { true }

        it { is_expected.to be false }

        context 'press_analysts' do
          let(:any_press_analysts) { true }

          it { is_expected.to be true }
        end
      end
    end
  end

  context 'Entity Helpers' do
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

      context 'Resource' do
        let(:noid) { file_set.id }
        let(:file_set) { create(:public_file_set) }

        it { is_expected.to be_an_instance_of(Hyrax::FileSetPresenter) }
      end
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

    describe '#url' do
      subject { described_class.url(entity) }

      let(:entity) { described_class.from_noid(noid) }
      let(:noid) { 'validnoid' }
      let(:data) { {} }

      before { allow(ActiveFedora::SolrService).to receive(:query).with("{!terms f=id}#{noid}", rows: 1).and_return([data]) }

      it { is_expected.to be nil }

      context 'monograph' do
        let(:entity) { Sighrax::Monograph.send(:new, noid, data) }

        it { is_expected.to eq "http://test.host/concern/monographs/validnoid" }
      end

      context 'score' do
        let(:entity) { Sighrax::Score.send(:new, noid, data) }

        it { is_expected.to eq "http://test.host/concern/scores/validnoid" }
      end

      context 'asset' do
        let(:entity) { Sighrax::Resource.send(:new, noid, data) }

        it { is_expected.to eq "http://test.host/concern/file_sets/validnoid" }
      end

      context 'interactive map' do
        let(:entity) { Sighrax::InteractiveMap.send(:new, noid, data) }

        it { is_expected.to eq "http://test.host/concern/file_sets/validnoid" }
      end
    end
  end
end
