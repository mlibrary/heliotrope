# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BreadcrumbsHelper do
  let!(:press) { create(:press, subdomain: "blue", name: "Blue Press") }
  let(:mono_doc) do
    SolrDocument.new(id: 1,
                     title_tesim: ["Monograph Title"],
                     press_tesim: "blue",
                     has_model_ssim: ['Monograph'],
                     member_ids_ssim: ['2'])
  end
  let(:file_set_doc) do
    SolrDocument.new(id: 2,
                     title_tesim: ["FileSet Title"],
                     has_model_ssim: ["FileSet"],
                     monograph_id_ssim: 1)
  end
  let(:presenter) { Hyrax::MonographPresenter.new(mono_doc, nil) }
  let(:file_set_presenter) { Hyrax::FileSetPresenter.new(file_set_doc, nil) }

  before do
    ActiveFedora::SolrService.add([mono_doc.to_h, file_set_doc.to_h])
    ActiveFedora::SolrService.commit
  end

  describe "when on a monograph catalog page" do
    let(:controller_name) { 'monograph_catalog' }

    context "with no parent press" do
      it "returns the right breadcrumbs" do
        @presenter = presenter
        expect(breadcrumbs).to match_array([{ href: "/blue",
                                              text: "Home",
                                              class: "" },
                                            { href: "",
                                              text: "Monograph Title",
                                              class: "active" }])
      end
    end

    context "with a parent press" do
      let(:parent) { create(:press, subdomain: "maize", name: "Maize Press") }

      it "returns the right breadcrumbs" do
        @presenter = presenter
        press.parent_id = parent.id
        press.save!
        expect(breadcrumbs).to match_array([{ href: "/maize",
                                              text: "Home",
                                              class: "" },
                                            { href: "/blue",
                                              text: "Blue Press",
                                              class: "" },
                                            { href: "",
                                              text: "Monograph Title",
                                              class: "active" }])
      end
    end
  end

  describe "when on a monograph show page" do
    let(:controller_name) { 'monographs' }

    context "with no parent press" do
      it "returns the right breadcrumbs" do
        @presenter = presenter
        expect(breadcrumbs).to match_array([{ href: "/blue",
                                              text: "Home",
                                              class: "" },
                                            { href: "/concern/monographs/1",
                                              text: "Monograph Title",
                                              class: "" },
                                            { href: "",
                                              text: "Show",
                                              class: "active" }])
      end
    end

    context "with a parent press" do
      let(:parent) { create(:press, subdomain: "maize", name: "Maize Press") }

      it "returns the right breadcrumbs" do
        @presenter = presenter
        press.parent_id = parent.id
        press.save!
        expect(breadcrumbs).to match_array([{ href: "/maize",
                                              text: "Home",
                                              class: "" },
                                            { href: "/blue",
                                              text: "Blue Press",
                                              class: "" },
                                            { href: "/concern/monographs/1",
                                              text: "Monograph Title",
                                              class: "" },
                                            { href: "",
                                              text: "Show",
                                              class: "active" }])
      end
    end
  end

  describe "when on a file_set/asset page" do
    let(:controller_name) { 'file_sets' }

    context "with no parent press" do
      it "returns the right breadcrumbs" do
        @presenter = file_set_presenter
        allow(@presenter).to receive(:parent).and_return(presenter)
        expect(breadcrumbs).to match_array([{ href: "/blue",
                                              text: "Home",
                                              class: "" },
                                            { href: "/concern/monographs/1",
                                              text: "Monograph Title",
                                              class: "" },
                                            { href: "",
                                              text: "FileSet Title",
                                              class: "active" }])
      end
    end

    context "with a parent press" do
      let(:parent) { create(:press, subdomain: "maize", name: "Maize Press") }

      it "returns the right breadcrumbs" do
        @presenter = file_set_presenter
        allow(@presenter).to receive(:parent).and_return(presenter)
        press.parent_id = parent.id
        press.save!
        expect(breadcrumbs).to match_array([{ href: "/maize",
                                              text: "Home",
                                              class: "" },
                                            { href: "/blue",
                                              text: "Blue Press",
                                              class: "" },
                                            { href: "/concern/monographs/1",
                                              text: "Monograph Title",
                                              class: "" },
                                            { href: "",
                                              text: "FileSet Title",
                                              class: "active" }])
      end
    end
  end
end
