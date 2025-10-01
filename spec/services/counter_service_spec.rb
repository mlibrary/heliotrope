# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterService do
  # The CounterService gathers stats needed to build COUNTER v5 reports.
  # Fun time reading is here: https://www.projectcounter.org
  # See also HELIO-1376
  let(:controller) { Hyrax::FileSetsController.new }
  let(:press) { create(:press) }
  let(:fs_doc) do
    SolrDocument.new(id: 'id',
                     has_model_ssim: ['FileSet'],
                     permissions_expiration_date_ssim: [],
                     visibility_ssi: 'open',
                     read_access_group_ssim: ["public"],
                     monograph_id_ssim: 'mono_id')
  end
  let(:mono_doc) do
    SolrDocument.new(id: 'mono_id',
                     has_model_ssim: ['Monograph'],
                     visibility_ssi: 'open',
                     member_ids_ssim: ['id'],
                     press_tesim: [press.subdomain],
                     read_access_group_ssim: ["public"])
  end
  let(:fs_presenter) { Hyrax::FileSetPresenter.new(fs_doc, nil) }
  let(:mono_presenter) { Hyrax::MonographPresenter.new(mono_doc, nil) }

  before do
    ActiveFedora::SolrService.add([mono_doc.to_h, fs_doc.to_h])
    ActiveFedora::SolrService.commit
  end

  describe '#from' do
    context "with a correct controller and presenter" do
      it "creates a CounterService object" do
        expect(described_class.from(controller, fs_presenter)).to be_an_instance_of(described_class)
      end
    end

    context 'with the Hyrax::DownloadsController' do
      let!(:controller) { Hyrax::DownloadsController.new }

      it "creates a CounterService object" do
        expect(described_class.from(controller, fs_presenter)).to be_an_instance_of(described_class)
      end
    end

    context "with the wrong controller or presenter" do
      before { allow(fs_presenter.class).to receive(:name).and_return("OtherPresenter") }

      it "creates a CounterServiceNullObject" do
        expect(described_class.from(controller, fs_presenter)).to be_an_instance_of(CounterServiceNullObject)
      end
    end
  end

  describe "#null_object" do
    it "returns a CounterServiceNullObject" do
      expect(described_class.null_object(controller, fs_presenter).is_a?(CounterServiceNullObject)).to be true
    end
  end

  describe "the null object #count" do
    let(:controller) { CatalogController.new }

    before do
      @message = 'message'
      allow(Rails.logger).to receive(:error).with(any_args) { |value| @message = value }
    end

    it "responds with a logged error" do
      CounterServiceNullObject.new(controller, fs_presenter).count
      expect(@message).not_to eq 'message'
      expect(@message).to eq "Can't use CounterService for #{controller.class.name} or #{fs_presenter.class.name}"
    end
  end

  describe "#allowed_controllers" do
    it "limits the allowed controllers" do
      expect(described_class.allowed_controllers).to eq ["EPubsController",
                                                         "Hyrax::FileSetsController",
                                                         "Hyrax::DownloadsController",
                                                         "MonographCatalogController",
                                                         "EmbedController",
                                                         "EbooksController",
                                                         "EpubEbooksController"]
    end
  end

  describe "#allowed presenters" do
    it "limits the allowed presenters" do
      expect(described_class.allowed_presenters).to eq ["Hyrax::FileSetPresenter", "Hyrax::MonographPresenter"]
    end
  end

  describe "#session" do
    let(:request) { double("request") }
    let(:now) { double("now") }

    before do
      allow(controller).to receive(:request).and_return(request)
      allow(controller.request).to receive(:remote_ip).and_return("99.99.99.99")
      allow(controller.request).to receive(:user_agent).and_return("Mozilla/5.0")
      allow(DateTime).to receive(:now).and_return(now)
      allow(now).to receive(:strftime).with('%Y-%m-%d').and_return("2020-10-17")
      allow(now).to receive(:hour).and_return('13')
    end

    it "returns a session" do
      expect(described_class.from(controller, fs_presenter).session).to eq "99.99.99.99|Mozilla/5.0|2020-10-17|13"
    end
  end

  describe "#access_type" do
    let(:fedora_monograph) { instance_double(ActiveFedora::Base, update_index: true) }
    let!(:the_world_institution) { create(:institution, identifier: Settings.world_institution_identifier, name: "The World", display_name: "Unknown Institution aka 'The World'") }

    before do
      allow(Monograph).to receive(:find).with(mono_presenter.id).and_return(fedora_monograph)
    end

    after do
      FeaturedRepresentative.destroy_all
    end

    context "with a restricted book" do
      let(:component) { Greensub::Component.create!(identifier: mono_presenter.id, name: mono_presenter.title, noid: mono_presenter.id) }

      context "that is part of a free to read product" do
        let(:product) { Greensub::Product.create!(name: "UMPEBC Free to Read Online", identifier: "ebc_Free_To_Read") }

        before do
          product.components << component
          product.save!
          the_world_institution.create_product_license(product)
        end

        context "and the Monograph is not Open Access" do
          it "the monograph itself is 'Free_To_Read'" do
            expect(described_class.from(controller, mono_presenter).access_type).to eq 'Free_To_Read'
          end

          it "the book's epub is Free_To_Read" do
            FeaturedRepresentative.create(work_id: mono_presenter.id, file_set_id: fs_presenter.id, kind: "epub")
            expect(described_class.from(controller, fs_presenter).access_type).to eq 'Free_To_Read'
          end

          it "one of the book's non-book filesets is Free_To_Read" do
            expect(described_class.from(controller, fs_presenter).access_type).to eq 'Free_To_Read'
          end
        end

        # This probably won't ever happen, there's no reason to add an OA book to a Free_To_Read product
        # but if it does, we want the COUNTER report to show "Open", not free to read
        context "and the Monograph is Open Access" do
          before do
            allow(mono_presenter).to receive(:open_access?).and_return(true)
          end

          it "the mono_presenter itsel is Open" do
            expect(described_class.from(controller, mono_presenter).access_type).to eq 'Open'
          end

          it "the book's epubis Open" do
            FeaturedRepresentative.create(work_id: mono_presenter.id, file_set_id: fs_presenter.id, kind: "epub")
            expect(described_class.from(controller, fs_presenter).access_type).to eq 'Free_To_Read'
          end

          # Most FileSets are going to be free to read
          it "ne of the book's non-book filesets is Free_To_Read" do
            expect(described_class.from(controller, fs_presenter).access_type).to eq 'Free_To_Read'
          end
        end
      end

      context "that is part of a normal restricted product" do
        let(:product) { Greensub::Product.create!(name: "UMPEBC", identifier: "ebc") }
        let(:institution) { create(:institution, identifier: 495, name: "a") }

        before do
          product.components << component
          product.save!
        end

        context "when the requesting institution has a license" do
          before do
            institution.create_product_license(product)
            allow(controller).to receive(:current_institutions).and_return([institution])
          end

          context "and the mono_presenter is not Open Access" do
            it "the monograph itself is Controlled" do
              expect(described_class.from(controller, mono_presenter).access_type).to eq 'Controlled'
            end

            it "the 'book-type' FileSetis Controlled" do
              FeaturedRepresentative.create(work_id: mono_presenter.id, file_set_id: fs_presenter.id, kind: "pdf_ebook")
              expect(described_class.from(controller, fs_presenter).access_type).to eq 'Controlled'
            end

            it "one of the book's non-book filesets is Free_To_Read" do
              expect(described_class.from(controller, fs_presenter).access_type).to eq 'Free_To_Read'
            end
          end

          context "and the Monograph is Open Access" do
            before do
              allow(mono_presenter).to receive(:open_access?).and_return(true)
            end

            it "the monograph itself is Open" do
              expect(described_class.from(controller, mono_presenter).access_type).to eq 'Open'
            end

            it "a 'book-type' FileSet is Open" do
              FeaturedRepresentative.create(work_id: mono_presenter.id, file_set_id: fs_presenter.id, kind: "audiobook")
              expect(described_class.from(controller, fs_presenter).access_type).to eq 'Controlled'
            end
            # Most FileSets are going to be free to read
            it "the book's non-book fileset is Free_To_Read" do
              expect(described_class.from(controller, fs_presenter).access_type).to eq 'Free_To_Read'
            end
          end
        end

        context "when the requesting institution has no license" do
          before do
            allow(controller).to receive(:current_institutions).and_return([institution])
          end

          context "and the Monograph is Open Access" do
            before do
              allow(mono_presenter).to receive(:open_access?).and_return(true)
            end

            it "the monograph itself is Open" do
              expect(described_class.from(controller, mono_presenter).access_type).to eq 'Open'
            end

            it "a 'book-type' FileSet is Open" do
              FeaturedRepresentative.create(work_id: mono_presenter.id, file_set_id: fs_presenter.id, kind: "audiobook")
              expect(described_class.from(controller, fs_presenter).access_type).to eq 'Controlled'
            end
            # Most FileSets are going to be free to read
            it "the book's non-book filesets are Free_To_Read" do
              expect(described_class.from(controller, fs_presenter).access_type).to eq 'Free_To_Read'
            end
          end

          context "and the Monograph is not Open Access" do
            it "the monograph itself is Controlled" do
              expect(described_class.from(controller, mono_presenter).access_type).to eq 'Controlled'
            end

            it "a 'book-type' FileSet is Contolled" do
              FeaturedRepresentative.create(work_id: mono_presenter.id, file_set_id: fs_presenter.id, kind: "audiobook")
              expect(described_class.from(controller, fs_presenter).access_type).to eq 'Controlled'
            end
            # Most FileSets are going to be free to read
            it "the book's non-book filesets are Free_To_Read" do
              expect(described_class.from(controller, fs_presenter).access_type).to eq 'Free_To_Read'
            end
          end
        end
      end
    end

    context "with an unrestricted book" do
      before do
        allow(Greensub::Component).to receive(:find_by).with(noid: mono_presenter.id).and_return(false)
      end

      context "and the Monograph is not Open Access" do
        it "the monograph itself is Free_To_Read" do
          expect(described_class.from(controller, mono_presenter).access_type).to eq 'Free_To_Read'
        end

        it "a 'book-type' FileSet is Contolled" do
          FeaturedRepresentative.create(work_id: mono_presenter.id, file_set_id: fs_presenter.id, kind: "mobi")
          expect(described_class.from(controller, fs_presenter).access_type).to eq 'Free_To_Read'
        end
        # Most FileSets are going to be free to read
        it "the book's non-book filesets are Free_To_Read" do
          expect(described_class.from(controller, fs_presenter).access_type).to eq 'Free_To_Read'
        end
      end

      context "and the Monograph is Open Access" do
        before do
          allow(mono_presenter).to receive(:open_access?).and_return(true)
          # rspec is being weird on these specs, adding the below works (even though the above should be enough)
          allow(fs_presenter.parent).to receive(:open_access?).and_return(true)
        end

        it "the monograph itself is Open" do
          expect(described_class.from(controller, mono_presenter).access_type).to eq 'Open'
        end

        it "a 'book-type' FileSet is Open" do
          FeaturedRepresentative.create(work_id: mono_presenter.id, file_set_id: fs_presenter.id, kind: "pdf_ebook")
          expect(described_class.from(controller, fs_presenter).access_type).to eq 'Open'
        end
        # Most FileSets are going to be free to read
        it "the book's non-book filesets are Free_To_Read" do
          expect(described_class.from(controller, fs_presenter).access_type).to eq 'Free_To_Read'
        end
      end
    end

    context "with a non-book-type asset with no permissions_expiration_date" do
      before do
        allow(Greensub::Component).to receive(:find_by).with(noid: mono_presenter.id).and_return(false)
      end

      it "is Open" do
        expect(described_class.from(controller, fs_presenter).access_type).to eq 'Free_To_Read'
      end
    end

    context "with a non-book-type asset with a permissions_expiration_date" do
      before do
        allow(Greensub::Component).to receive(:find_by).with(noid: mono_presenter.id).and_return(false)
        allow(fs_presenter).to receive(:permissions_expiration_date).and_return("2020-01-27")
      end

      it "is Controlled" do
        expect(described_class.from(controller, fs_presenter).access_type).to eq 'Controlled'
      end
    end
  end

  describe "#count" do
    context "file_sets" do
      let(:request) { double("request") }
      let(:now) { double("now") }

      before do
        allow(controller).to receive(:request).and_return(request)
        allow(controller.request).to receive(:remote_ip).and_return("99.99.99.99")
        allow(controller.request).to receive(:user_agent).and_return("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.75 Safari/537.36")
        allow(DateTime).to receive(:now).and_return(now)
        allow(now).to receive(:strftime).with('%Y-%m-%d').and_return("2020-10-17")
        allow(now).to receive(:hour).and_return('13')
        allow(Greensub::Component).to receive(:find_by).with(noid: mono_presenter.id).and_return(false)
      end

      after { CounterReport.destroy_all }

      context "a user with NO institutions that is not a Robot" do
        before do
          Greensub::Institution.create(identifier: 0, name: "Unknown Institution", display_name: "World")
          allow(controller).to receive(:current_institutions).and_return([])
        end

        it "adds an 'Unknown Institution' (aka: 'The World') COUNT" do
          expect { described_class.from(controller, fs_presenter).count }
            .to change(CounterReport, :count)
            .by(1)
        end
      end

      context "a user with NO institutions that is a Robot" do
        before do
          Greensub::Institution.create(identifier: 0, name: "Unknown Institution")
          allow(controller).to receive(:current_institutions).and_return([])
          allow(controller.request).to receive(:user_agent).and_return("some-bot/1.0")
        end

        it "doesn't add COUNTER stats" do
          expect { described_class.from(controller, fs_presenter).count }
            .to change(CounterReport, :count)
            .by(0)
        end
      end

      context "a user with an institution downloading an asset" do
        before do
          allow(controller).to receive(:current_institutions).and_return([Greensub::Institution.new(identifier: 495, name: "a")])
        end

        it "adds a COUNTER stat row" do
          described_class.from(controller, fs_presenter).count(request: 1)

          cr = CounterReport.first

          expect(cr.noid).to eq fs_presenter.id
          expect(cr.model).to eq "FileSet"
          expect(cr.press).to eq press.id
          expect(cr.parent_noid).to eq fs_presenter.monograph_id
          expect(cr.session).to eq "99.99.99.99|Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.75 Safari/537.36|2020-10-17|13"
          expect(cr.institution).to eq 495
          expect(cr.investigation).to eq 1
          expect(cr.section).to be nil
          expect(cr.section_type).to be nil
          expect(cr.request).to eq 1
          expect(cr.turnaway).to be nil
          expect(cr.access_type).to eq "Free_To_Read"
        end
      end

      context "a user with 2 institutions" do
        before do
          allow(controller).to receive(:current_institutions).and_return([Greensub::Institution.new(identifier: 12, name: "a"),
                                                                          Greensub::Institution.new(identifier: 65, name: "b")])
        end

        it "creates 2 counter report rows" do
          expect { described_class.from(controller, fs_presenter).count }
            .to change(CounterReport, :count)
            .by(2)
          expect(CounterReport.first.institution).to eq 12
          expect(CounterReport.second.institution).to eq 65
          expect(CounterReport.first.press).to eq press.id
          expect(CounterReport.first.parent_noid).to eq fs_presenter.monograph_id
          expect(CounterReport.second.parent_noid).to eq fs_presenter.monograph_id
        end
      end

      context "a user with a LIT/Staff IP (490)" do
        before do
          allow(controller).to receive(:current_institutions).and_return([Greensub::Institution.new(identifier: 1, name: "u of m"),
                                                                          Greensub::Institution.new(identifier: 490, name: "lit")])
        end

        it "creates 0 counter report rows" do
          expect { described_class.from(controller, fs_presenter).count }
          .to change(CounterReport, :count)
          .by(0)
        end
      end

      context "a crawler, CLOCKSS/LOCKSS (2334)" do
        before do
          allow(controller).to receive(:current_institutions).and_return([Greensub::Institution.new(identifier: 2334, name: "CLOCKS/LOCKS")])
        end

        it "creates 0 counter report rows" do
          expect { described_class.from(controller, fs_presenter).count }
          .to change(CounterReport, :count)
          .by(0)
        end
      end

      context "if the file_set is not 'published'/open" do
        let(:presenter) do
          Hyrax::FileSetPresenter.new(SolrDocument.new(id: 'id',
                                                       has_model_ssim: ['FileSet'],
                                                       permissions_expiration_date_ssim: [],
                                                       visibility_ssi: 'restricted',
                                                       read_access_group_ssim: []), nil)
        end

        before do
          allow(controller).to receive(:current_institutions).and_return([Greensub::Institution.new(identifier: 495, name: "a")])
        end

        it "doesn't add COUNTER stats" do
          expect(presenter.visibility).to eq 'restricted'
          expect { described_class.from(controller, presenter).count }
            .to change(CounterReport, :count)
            .by(0)
        end
      end
    end

    context "monographs" do
      let(:controller) { MonographCatalogController.new }
      let(:request) { double("request") }
      let(:now) { double("now") }
      let(:press) { create(:press) }
      let!(:the_world_institution) { create(:institution, identifier: Settings.world_institution_identifier, name: "The World", display_name: "Unknown Institution aka 'The World'") }


      before do
        allow(controller).to receive(:request).and_return(request)
        allow(controller.request).to receive(:remote_ip).and_return("99.99.99.99")
        allow(controller.request).to receive(:user_agent).and_return("Mozilla/5.0")
        allow(DateTime).to receive(:now).and_return(now)
        allow(now).to receive(:strftime).with('%Y-%m-%d').and_return("2020-10-17")
        allow(now).to receive(:hour).and_return('13')

        allow(controller).to receive(:current_institutions).and_return([Greensub::Institution.new(identifier: 1, name: "a")])
      end

      context "if restricted" do
        let(:component) { Greensub::Component.create!(identifier: mono_presenter.id, name: mono_presenter.title, noid: mono_presenter.id) }
        let(:product) { Greensub::Product.create!(name: "UMPEBC", identifier: "ebc_complete") }
        let(:fedora_monograph) { instance_double(ActiveFedora::Base, update_index: true) }

        before do
          allow(Monograph).to receive(:find).with(mono_presenter.id).and_return(fedora_monograph)
          product.components << component
          product.save!
        end

        it "adds a Controlled Monograph COUNTER stat row" do
          expect { described_class.from(controller, mono_presenter).count }
            .to change(CounterReport, :count)
            .by(1)
          expect(CounterReport.first.noid).to eq mono_presenter.id
          expect(CounterReport.first.parent_noid).to eq mono_presenter.id
          expect(CounterReport.first.model).to eq 'Monograph'
          expect(CounterReport.first.investigation).to eq 1
          expect(CounterReport.first.request).to be_nil
          expect(CounterReport.first.access_type).to eq 'Controlled'
        end
      end

      context "if not restricted" do
        before { allow(Greensub::Component).to receive(:find_by).with(noid: mono_presenter.id).and_return(false) }

        it "adds an Free_To_Read Monograph COUNTER stat row" do
          expect { described_class.from(controller, mono_presenter).count }
            .to change(CounterReport, :count)
            .by(1)
          expect(CounterReport.first.access_type).to eq 'Free_To_Read'
        end
      end
    end
  end

  describe "#robot?" do
    let(:file) { File.read(Rails.root.join('spec', 'fixtures', 'feed', 'counter_robots.json')) }
    let(:request) { double("request") }

    before do
      allow(controller).to receive(:request).and_return(request)
      allow(request).to receive(:user_agent).and_return(user_agent)
      allow(Rails.cache).to receive(:fetch).and_return(JSON.load(file).map { |entry| entry["pattern"] })
    end

    context "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.83 Safari/537.36" do
      let(:user_agent) { "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.83 Safari/537.36" }

      it "is not a robot" do
        expect(described_class.from(controller, fs_presenter).robot?).to eq false
      end
    end

    context "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.2 Safari/605.1.15" do
      let(:user_agent) { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.2 Safari/605.1.15" }

      it "is not a robot" do
        expect(described_class.from(controller, fs_presenter).robot?).to eq false
      end
    end

    context "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" do
      let(:user_agent) { "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" }

      it "is a robot" do
        expect(described_class.from(controller, fs_presenter).robot?).to eq true
      end
    end

    context "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)" do
      let(:user_agent) { "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)" }

      it "is a robot" do
        expect(described_class.from(controller, fs_presenter).robot?).to eq true
      end
    end
  end
end
