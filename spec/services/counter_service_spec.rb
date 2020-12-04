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
  let(:presenter) { Hyrax::FileSetPresenter.new(fs_doc, nil) }
  let(:monograph) { Hyrax::MonographPresenter.new(mono_doc, nil) }

  before do
    ActiveFedora::SolrService.add([mono_doc.to_h, fs_doc.to_h])
    ActiveFedora::SolrService.commit
  end

  describe '#from' do
    context "with a correct controller and presenter" do
      it "creates a CounterService object" do
        expect(described_class.from(controller, presenter)).to be_an_instance_of(described_class)
      end
    end

    context 'with the Hyrax::DownloadsController' do
      let!(:controller) { Hyrax::DownloadsController.new }

      it "creates a CounterService object" do
        expect(described_class.from(controller, presenter)).to be_an_instance_of(described_class)
      end
    end

    context "with the wrong controller or presenter" do
      before { allow(presenter.class).to receive(:name).and_return("OtherPresenter") }

      it "creates a CounterServiceNullObject" do
        expect(described_class.from(controller, presenter)).to be_an_instance_of(CounterServiceNullObject)
      end
    end
  end

  describe "#null_object" do
    it "returns a CounterServiceNullObject" do
      expect(described_class.null_object(controller, presenter).is_a?(CounterServiceNullObject)).to be true
    end
  end

  describe "the null object #count" do
    let(:controller) { CatalogController.new }

    before do
      @message = 'message'
      allow(Rails.logger).to receive(:error).with(any_args) { |value| @message = value }
    end

    it "responds with a logged error" do
      CounterServiceNullObject.new(controller, presenter).count
      expect(@message).not_to eq 'message'
      expect(@message).to eq "Can't use CounterService for #{controller.class.name} or #{presenter.class.name}"
    end
  end

  describe "#allowed_controllers" do
    it "limits the allowed controllers" do
      expect(described_class.allowed_controllers).to eq ["EPubsController",
                                                         "Hyrax::FileSetsController",
                                                         "Hyrax::DownloadsController",
                                                         "MonographCatalogController",
                                                         "EmbedController",
                                                         "EbooksController"]
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
      expect(described_class.from(controller, presenter).session).to eq "99.99.99.99|Mozilla/5.0|2020-10-17|13"
    end
  end

  describe "#access_type" do
    context "with a restricted epub" do
      before do
        allow(HandleNet).to receive(:path).and_return(true)
        allow(Greensub::Component).to receive(:find_by).with(noid: monograph.id).and_return(true)
      end

      it "is 'Controlled'" do
        expect(described_class.from(controller, presenter).access_type).to eq 'Controlled'
      end

      context "the Monograph is Open Access" do
        let(:mono_doc) do
          SolrDocument.new(id: 'mono_id',
                           has_model_ssim: ['Monograph'],
                           visibility_ssi: 'open',
                           member_ids_ssim: ['id'],
                           press_tesim: [press.subdomain],
                           read_access_group_ssim: ["public"],
                           open_access_tesim: ["yes"])
        end

        it "is 'OA_Gold'" do
          expect(described_class.from(controller, presenter).access_type).to eq 'OA_Gold'
        end
      end
    end

    context "with an unrestricted epub" do
      before do
        allow(HandleNet).to receive(:path).and_return(true)
        allow(Greensub::Component).to receive(:find_by).with(noid: monograph.id).and_return(false)
      end

      it "is OA_Gold" do
        expect(described_class.from(controller, monograph).access_type).to eq 'OA_Gold'
      end
    end

    context "with an asset with no permissions_expiration_date" do
      before do
        allow(HandleNet).to receive(:path).and_return(true)
        allow(Greensub::Component).to receive(:find_by).with(noid: monograph.id).and_return(false)
      end

      it "is OA_Gold" do
        expect(described_class.from(controller, presenter).access_type).to eq 'OA_Gold'
      end
    end

    context "with an asset with a permissions_expiration_date" do
      before do
        allow(HandleNet).to receive(:path).and_return(true)
        allow(Greensub::Component).to receive(:find_by).with(noid: monograph.id).and_return(false)
        allow(presenter).to receive(:permissions_expiration_date).and_return("2020-01-27")
      end

      it "is Controlled" do
        expect(described_class.from(controller, presenter).access_type).to eq 'Controlled'
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
        allow(HandleNet).to receive(:path).and_return(true)
        allow(Greensub::Component).to receive(:find_by).with(noid: monograph.id).and_return(false)
      end

      after { CounterReport.destroy_all }

      context "a user with NO institutions that is not a Robot" do
        before do
          Greensub::Institution.create(identifier: 0, name: "Unknown Institution")
          allow(controller).to receive(:current_institutions).and_return([])
        end

        it "adds an 'Unknown Institution' (aka: 'The World') COUNT" do
          expect { described_class.from(controller, presenter).count }
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
          expect { described_class.from(controller, presenter).count }
            .to change(CounterReport, :count)
            .by(0)
        end
      end

      context "a user with an institution downloading an asset" do
        before do
          allow(controller).to receive(:current_institutions).and_return([Greensub::Institution.new(identifier: 495, name: "a")])
        end

        it "adds a COUNTER stat row" do
          described_class.from(controller, presenter).count(request: 1)

          cr = CounterReport.first

          expect(cr.noid).to eq presenter.id
          expect(cr.model).to eq "FileSet"
          expect(cr.press).to eq press.id
          expect(cr.parent_noid).to eq presenter.monograph_id
          expect(cr.session).to eq "99.99.99.99|Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.75 Safari/537.36|2020-10-17|13"
          expect(cr.institution).to eq 495
          expect(cr.investigation).to eq 1
          expect(cr.section).to be nil
          expect(cr.section_type).to be nil
          expect(cr.request).to eq 1
          expect(cr.turnaway).to be nil
          expect(cr.access_type).to eq "OA_Gold"
        end
      end

      context "a user with 2 institutions" do
        before do
          allow(controller).to receive(:current_institutions).and_return([Greensub::Institution.new(identifier: 12, name: "a"),
                                                                          Greensub::Institution.new(identifier: 65, name: "b")])
        end

        it "creates 2 counter report rows" do
          expect { described_class.from(controller, presenter).count }
            .to change(CounterReport, :count)
            .by(2)
          expect(CounterReport.first.institution).to eq 12
          expect(CounterReport.second.institution).to eq 65
          expect(CounterReport.first.press).to eq press.id
          expect(CounterReport.first.parent_noid).to eq presenter.monograph_id
          expect(CounterReport.second.parent_noid).to eq presenter.monograph_id
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
      let(:presenter) do
        Hyrax::MonographPresenter.new(SolrDocument.new(id: 'mono12456',
                                                       has_model_ssim: ['Monograph'],
                                                       press_tesim: [press.subdomain],
                                                       visibility_ssi: 'open',
                                                       read_access_group_ssim: ["public"]), nil)
      end

      let(:request) { double("request") }
      let(:now) { double("now") }
      let(:press) { create(:press) }

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
        before { allow(Greensub::Component).to receive(:find_by).with(noid: presenter.id).and_return(true) }

        it "adds a Controlled Monograph COUNTER stat row" do
          expect { described_class.from(controller, presenter).count }
            .to change(CounterReport, :count)
            .by(1)
          expect(CounterReport.first.noid).to eq presenter.id
          expect(CounterReport.first.parent_noid).to eq presenter.id
          expect(CounterReport.first.model).to eq 'Monograph'
          expect(CounterReport.first.investigation).to eq 1
          expect(CounterReport.first.request).to be_nil
          expect(CounterReport.first.access_type).to eq 'Controlled'
        end
      end

      context "if not restricted" do
        before { allow(Greensub::Component).to receive(:find_by).with(noid: presenter.id).and_return(false) }

        it "adds a OA_Gold Monograph COUNTER stat row" do
          expect { described_class.from(controller, presenter).count }
            .to change(CounterReport, :count)
            .by(1)
          expect(CounterReport.first.access_type).to eq 'OA_Gold'
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
        expect(described_class.from(controller, presenter).robot?).to eq false
      end
    end

    context "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.2 Safari/605.1.15" do
      let(:user_agent) { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.2 Safari/605.1.15" }

      it "is not a robot" do
        expect(described_class.from(controller, presenter).robot?).to eq false
      end
    end

    context "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" do
      let(:user_agent) { "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" }

      it "is a robot" do
        expect(described_class.from(controller, presenter).robot?).to eq true
      end
    end

    context "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)" do
      let(:user_agent) { "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)" }

      it "is a robot" do
        expect(described_class.from(controller, presenter).robot?).to eq true
      end
    end
  end
end
