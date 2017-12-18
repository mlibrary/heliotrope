# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BreadcrumbsHelper do
  let!(:press) { create(:press, subdomain: "blue", name: "Blue Press") }
  let(:monograph_presenter) { Hyrax::MonographPresenter.new(SolrDocument.new(id: 1,
                                                                             title_tesim: ["Monograph Title"],
                                                                             press_tesim: "blue",
                                                                             has_model_ssim: ['Monograph']), nil) }

  describe "when on a monograph catalog page" do
    context "with no parent press" do
      it "returns the right breadcrumbs" do
        @monograph_presenter = monograph_presenter
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
        @monograph_presenter = monograph_presenter
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

  describe "when on a file_set/asset page" do
    let(:file_set_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(id: 2,
                                                                            title_tesim: ["FileSet Title"],
                                                                            has_model_ssim: ["FileSet"],
                                                                            monograph_id_ssim: 1), nil) }
    context "with no parent press" do
      it "returns the right breadcrumbs" do
        @presenter = file_set_presenter
        @presenter.monograph_presenter = monograph_presenter
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
        @presenter.monograph_presenter = monograph_presenter
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
