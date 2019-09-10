# frozen_string_literal: true

require 'rails_helper'

describe RegisterFileSetDoisActor do
  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:monograph) do
    create(:monograph, press: press.subdomain,
                       user: user,
                       title: ["A Book"],
                       doi: "10.xxx/this.thing")
  end
  let(:fs1) { create(:file_set, title: ['Cover']) }
  let(:fs2) { create(:file_set, title: ['File1']) }
  let(:fs3) { create(:file_set, title: ['File2']) }
  let(:env) { Hyrax::Actors::Environment.new(monograph, ability, attributes) }

  before do
    monograph.ordered_members = [fs1, fs2, fs3]
    monograph.save!
    fs1.save!
    fs2.save!
    fs3.save!
  end

  describe "#update" do
    context "when the press can't make dois" do
      let(:press) { create(:press) }
      let(:attributes) { {} }

      it "DOI creation is NOT called" do
        allow(Crossref::FileSetMetadata).to receive(:new)
        expect(middleware.update(env)).to be true
        expect(Crossref::FileSetMetadata).not_to have_received(:new)
      end
    end

    context "if not going from Private to Public" do
      let(:press) { create(:press, doi_creation: true) }
      let(:attributes) { { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE } }

      it "DOI creation is NOT called" do
        allow(Crossref::FileSetMetadata).to receive(:new)
        expect(middleware.update(env)).to be true
        expect(Crossref::FileSetMetadata).not_to have_received(:new)
      end
    end

    context "if there are file_sets present" do
      let(:press) { create(:press, doi_creation: true) }
      let(:attributes) do
        {
          import_uploaded_files_ids: [1, 2, 3],
          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        }
      end

      it "DOI creation is NOT called" do
        allow(Crossref::FileSetMetadata).to receive(:new)
        expect(middleware.update(env)).to be true
        expect(Crossref::FileSetMetadata).not_to have_received(:new)
      end
    end

    context "if the monograph has no DOI" do
      let(:monograph) do
        create(:monograph, press: press.subdomain,
                           user: user,
                           title: ["A Book"])
      end
      let(:press) { create(:press, doi_creation: true) }
      let(:attributes) do
        {
          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        }
      end

      it "DOI creation is NOT called" do
        allow(Crossref::FileSetMetadata).to receive(:new)
        expect(middleware.update(env)).to be true
        expect(Crossref::FileSetMetadata).not_to have_received(:new)
      end
    end

    context "if the mongraph has no 'eligible' file_sets" do
      let(:press) { create(:press, doi_creation: true) }
      let(:attributes) do
        {
          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        }
      end

      # FileSets that "represent" the Monograph, that are basically the "same" as
      # the Monograph like: the cover, the epub (or any kind of "booK" type) do
      # not need DOIs as the Monograph DOI applies for them.
      before do
        monograph.representative_id = fs1.id
        FeaturedRepresentative.create(work_id: monograph.id, file_set_id: fs2.id, kind: 'epub')
        FeaturedRepresentative.create(work_id: monograph.id, file_set_id: fs3.id, kind: 'pdf_ebook')
        monograph.save!
      end

      it "DOI creation is NOT called" do
        allow(Crossref::FileSetMetadata).to receive(:new)
        expect(middleware.update(env)).to be true
        expect(Crossref::FileSetMetadata).not_to have_received(:new)
      end
    end

    context "if press can make DOIs AND private -> public AND no file_sets AND monograph has DOI" do
      let(:press) { create(:press, doi_creation: true) }
      let(:attributes) do
        {
          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        }
      end
      let(:metadata) { double('metadata') }
      let(:register) { double('register') }

      before do
        allow(Crossref::FileSetMetadata).to receive(:new).and_return(metadata)
        allow(metadata).to receive(:build).and_return(Nokogiri::XML("<xml>hello</xml>"))
        allow(Crossref::Register).to receive(:new).and_return(register)
        allow(register).to receive(:post).and_return(true)
      end

      it "DOI creation is called" do
        expect(middleware.update(env)).to be true
        expect(Crossref::FileSetMetadata).to have_received(:new)
        expect(metadata).to have_received(:build)
        expect(Crossref::Register).to have_received(:new)
        expect(register).to have_received(:post)
      end
    end
  end
end
