# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "monograph_catalog/index.html.erb" do
  def debug_puts(arg)
    puts arg if debug
  end

  I18n.load_path += Dir[Rails.root.join('config', 'locales', '*.yml').to_s]
  def t(value)
    translation = if value[0] == '.'
                    I18n.t('monograph_catalog.index' + value)
                  else
                    I18n.t(value)
                  end
    debug_puts "t(#{value}) #{translation}"
    raise translation if /translation missing/.match? translation
    value
  end

  let(:debug) { false }
  let(:current_ability) { double("ability") }
  let(:solr_doc) { SolrDocument.new(id: 'mono_id', title_tesim: ["Untitled"], has_model_ssim: ['Monograph']) }
  let(:monograph_presenter) { Hyrax::MonographPresenter.new(solr_doc, current_ability) }
  let(:ebook_download_presenter) { double("ebook_download_presenter") }

  before do
    ActiveFedora::SolrService.add([solr_doc.to_h])
    ActiveFedora::SolrService.commit
    stub_template "catalog/_search_sidebar" => "<!-- render-template-catalog/_search_sidebar -->"
    stub_template "catalog/_search_results" => "<!-- render-template-catalog/_search_results -->"
    assign(:monograph_presenter, monograph_presenter)
    assign(:ebook_download_presenter, ebook_download_presenter)
    allow(view).to receive(:t).with(any_args) { |value| value }
    allow(monograph_presenter).to receive(:date_uploaded).and_return(DateTime.now)
    allow(monograph_presenter).to receive(:creator).and_return([])
    allow(ebook_download_presenter).to receive(:downloadable_ebooks?).and_return(false)

    # see `ApplicationController::auth_for()`
    assign(:auth, Auth.new(Anonymous.new({}), Sighrax.from_presenter(monograph_presenter)))
  end

  describe 'provide: page_title' do
    subject { view.view_flow.content[:page_title] }

    let(:page_title) { 'PAGE-TITLE' }

    before do
      allow(monograph_presenter).to receive(:page_title).and_return(page_title)
      render
    end

    it do
      debug_puts subject.to_s
      is_expected.not_to be_empty
      is_expected.to eq page_title
    end
  end

  describe 'provide: page_class' do
    subject { view.view_flow.content[:page_class] }

    let(:page_class) { 'search monograph' }

    before do
      render
    end

    it do
      debug_puts subject.to_s
      is_expected.not_to be_empty
      is_expected.to eq page_class
    end
  end

  describe 'provide: page_header' do
    subject { view.view_flow.content[:page_header] }

    let(:page_title) { 'PAGE-TITLE' }
    let(:subdomain) { 'subdomain' }
    let!(:press) { create(:press, subdomain: subdomain) }

    before do
      allow(monograph_presenter).to receive(:title).and_return(page_title)
      allow(monograph_presenter).to receive(:subdomain).and_return(subdomain)
      allow(controller).to receive(:controller_name).and_return("monograph_catalog")
      render
    end

    it do
      debug_puts subject.to_s
      is_expected.not_to be_empty
      # Breadcrumbs
      is_expected.to match(/<li.*?>.*?<a.*?href="\/#{subdomain}">Home<\/a>.*?<\/li>/m)
      is_expected.to match(/<li.*?active.*?>.*?#{page_title}.*?<\/li>/m)
    end
  end

  describe 'index_monograph' do
    before { allow(monograph_presenter).to receive(:epub?).and_return(false) }

    context 'partial' do
      subject { response.body }

      let(:debug) { false }

      before { render }

      it 'renders' do
        debug_puts subject.to_s
        is_expected.to render_template(partial: '_index_monograph')
      end
    end

    context 'maincontent' do
      subject { response.body }

      let(:monograph_coins_title) { "MONOGRAPH-COINS-TITLE" }
      let(:authors) { "AUTHORS" }

      context 'default' do
        before do
          monograph_presenter.instance_eval('undef :monograph_coins_title')
          render
        end

        it do
          debug_puts subject.to_s
          is_expected.not_to be_empty
          is_expected.not_to match(/<span.*?class="Z3988".*?title=".*?".*?>.*?<\/span>/m)
          is_expected.not_to match t('monograph_catalog.index.show_page_button')
          is_expected.not_to match t('monograph_catalog.index.edit_page_button')
          is_expected.not_to match authors
          is_expected.not_to match(/<div.*?class="isbn".*?>.*?<\/div>/m)
          is_expected.not_to match t('isbn')
          is_expected.not_to match t('monograph_catalog.index.buy')
          is_expected.not_to match t('monograph_catalog.index.buy_book')
        end
      end

      context 'monograph_coins_title?' do
        before do
          allow(monograph_presenter).to receive(:monograph_coins_title?).and_return(true)
          allow(monograph_presenter).to receive(:monograph_coins_title).and_return(monograph_coins_title)
          render
        end

        it do
          debug_puts subject.to_s
          is_expected.to match(/<span.*?class="Z3988".*?title="#{monograph_coins_title}".*?>.*?<\/span>/m)
        end
      end

      context 'admin menu' do
        before do
          allow(view).to receive(:can?).and_call_original
          allow(monograph_presenter).to receive(:reader_ebook?).and_return(true)
          allow(monograph_presenter).to receive(:reader_ebook).and_return({ id: 'validnoid' })
        end

        context 'can? :read (i.e. just the Monograph itself)' do
          before do
            allow(view).to receive(:can?).with(:read).and_return(true)
            render
          end

          it 'shows no admin menu (i.e. an empty one, see comment)' do
            debug_puts subject.to_s
            # note the div itself is always present, probably for spacing reasons, albeit empty sometimes, like here
            is_expected.to have_css('.row.platform-admin', count: 1)
            is_expected.not_to match t('monograph_catalog.index.show_page_button')
            is_expected.not_to match t('monograph_catalog.index.edit_page_button')
            is_expected.not_to have_link(t('monograph_catalog.index.read_book'), href: epub_path('validnoid'), count: 1)
          end
        end

        context 'can? :read, stats_dashboard' do
          before do
            allow(view).to receive(:can?).with(:read, :stats_dashboard).and_return(true)
            render
          end

          it 'shows a limited admin menu with a read link' do
            debug_puts subject.to_s
            is_expected.to have_css('.row.platform-admin', count: 1)
            is_expected.not_to match t('monograph_catalog.index.show_page_button')
            is_expected.not_to match t('monograph_catalog.index.edit_page_button')
            is_expected.to have_link(t('monograph_catalog.index.read_book'), href: epub_path('validnoid'), count: 1)
          end
        end

        context 'can? :edit' do
          before do
            # can do everything, i.e. analyst stuff, as well as edit the Monograph
            allow(view).to receive(:can?).and_return(true)
            render
          end

          it 'shows a full admin menu with a manage, edit and read links' do
            debug_puts subject.to_s
            is_expected.to have_css('.row.platform-admin', count: 1)
            is_expected.to match t('monograph_catalog.index.show_page_button')
            is_expected.to match t('monograph_catalog.index.edit_page_button')
            is_expected.to have_link(t('monograph_catalog.index.read_book'), href: epub_path('validnoid'), count: 1)
          end
        end
      end

      # TODO: see https://tools.lib.umich.edu/jira/browse/HELIO-2224
      #
      # context 'pageviews' do
      #   before do
      #     allow(monograph_presenter).to receive(:pageviews).and_return("PAGEVIEWS")
      #     render
      #   end
      #
      #   it do
      #     debug_puts subject.to_s
      #     is_expected.to match t('pageviews_html')
      #   end
      # end

      context 'isbn' do
        before do
          allow(monograph_presenter).to receive(:isbn).and_return(["ISBN-HARDCOVER", "ISBN-PAPER", "ISBN-EBOOK"])
          render
        end

        it do
          debug_puts subject.to_s
          is_expected.to match t('isbn')
          is_expected.to match "ISBN-HARDCOVER.*ISBN-PAPER.*ISBN-EBOOK"
        end
      end

      context 'buy_url?' do
        before do
          allow(monograph_presenter).to receive(:buy_url?).and_return(true)
          allow(monograph_presenter).to receive(:buy_url).and_return("BUY-URL")
          render
        end

        it do
          debug_puts subject.to_s
          is_expected.to match t('monograph_catalog.index.buy')
          is_expected.to match t('monograph_catalog.index.buy_book')
        end
      end

      context 'handle' do
        before do
          allow(monograph_presenter).to receive(:citable_link)
                                .and_return([HandleNet::HANDLE_NET_PREFIX + HandleNet::FULCRUM_HANDLE_PREFIX + "999999999"])
          render
        end

        it do
          debug_puts subject.to_s
          is_expected.to match t('citable_link')
          is_expected.to match HandleNet::HANDLE_NET_PREFIX + HandleNet::FULCRUM_HANDLE_PREFIX + "999999999"
        end
      end

      describe 'registration required to view/download ebook' do
        let(:pdf_ebook_presenter) { instance_double("pdf_ebook_presenter", id: 'validnoid') }

        before do
          allow(view).to receive(:current_actor).and_return(Anonymous.new({}))
          allow_any_instance_of(EbookIntervalDownloadOperation).to receive(:allowed?).and_return(true)
          allow(monograph_presenter).to receive(:reader_ebook?).and_return(true)
          allow(monograph_presenter).to receive(:reader_ebook).and_return({ id: 'validnoid', 'visibility_ssi' => 'open' })
          allow(monograph_presenter).to receive(:epub?).and_return(false)
          allow(monograph_presenter).to receive(:toc?).and_return(true)
          allow(monograph_presenter).to receive(:pdf_ebook_presenter).and_return(pdf_ebook_presenter)
          allow(pdf_ebook_presenter).to receive(:intervals).and_return([instance_double(EBookIntervalPresenter,
                                                                                        title: 'Contents',
                                                                                        level: 1,
                                                                                        cfi: "page=6",
                                                                                        'downloadable?': true),
                                                                        instance_double(EBookIntervalPresenter,
                                                                                        title: 'Foreword | Timmy B. Wright',
                                                                                        level: 1, cfi: 'page=8',
                                                                                        'downloadable?': true)])

          allow_any_instance_of(Auth).to receive(:actor_unauthorized?).and_return(false)
        end

        context 'normal Monograph that does not require Google Form registration to access' do
          before do
            allow(monograph_presenter).to receive(:isbn).and_return(["ISBN-HARDCOVER", "ISBN-PAPER", "ISBN-EBOOK"])
            assign(:show_read_button, true)
            render
          end

          it 'uses the standard "read/download/buy" partial, links ToC entries' do
            debug_puts subject.to_s
            is_expected.to render_template(partial: '_read_download_buy')
            is_expected.to_not render_template(partial: '_read_download_buy_registration_required')
            is_expected.to match 'monograph_catalog.index.read_book'
            is_expected.to_not match 'https://docs.google.com/forms/d/e/1FAIpQLSeS5-ImSp3o9fmwl-hqL1o8EuvX6kUgzLnaETYHikSoJ5Bq_g/viewform'
            is_expected.to match 'toc-link'
          end
        end

        context 'Monograph that requires Google Form registration to access' do
          before do
            allow(monograph_presenter).to receive(:subdomain).and_return('ee')
            allow(monograph_presenter).to receive(:isbn).and_return(["ISBN-HARDCOVER", "ISBN-PAPER", "9781607857471"])
            render
          end

          it 'uses the registration required "read/download/buy" partial, does not link ToC entries' do
            debug_puts subject.to_s
            is_expected.to_not render_template(partial: '_read_download_buy')
            is_expected.to render_template(partial: '_read_download_buy_registration_required')
            is_expected.to_not match 'monograph_catalog.index.oa_registration_required_button'
            is_expected.to_not match 'https://docs.google.com/forms/d/e/1FAIpQLSeS5-ImSp3o9fmwl-hqL1o8EuvX6kUgzLnaETYHikSoJ5Bq_g/viewform'
            is_expected.to_not match 'toc-link'
          end

          context 'When it has both a readable ebook and a downloadable ebook' do
            before do
              assign(:ebook_download_presenter, ebook_download_presenter)
              allow(ebook_download_presenter).to receive(:downloadable_ebooks?).and_return(true)
              render
            end

            it 'shows the Google Form button' do
              debug_puts subject.to_s
              is_expected.to_not render_template(partial: '_read_download_buy')
              is_expected.to render_template(partial: '_read_download_buy_registration_required')
              is_expected.to match 'monograph_catalog.index.oa_registration_required_button'
              is_expected.to match 'https://docs.google.com/forms/d/e/1FAIpQLSeS5-ImSp3o9fmwl-hqL1o8EuvX6kUgzLnaETYHikSoJ5Bq_g/viewform'
              is_expected.to_not match 'toc-link'
            end
          end
        end
      end

      describe 'chapter links' do
        let(:pdf_ebook_presenter) { instance_double("pdf_ebook_presenter", id: 'validnoid') }

        before do
          allow(view).to receive(:current_actor).and_return(Anonymous.new({}))
          allow_any_instance_of(EbookIntervalDownloadOperation).to receive(:allowed?).and_return(true)
          allow(monograph_presenter).to receive(:reader_ebook?).and_return(true)
          allow(monograph_presenter).to receive(:reader_ebook).and_return({ id: 'validnoid', 'visibility_ssi' => 'open' })
          allow(monograph_presenter).to receive(:epub?).and_return(false)
          allow(monograph_presenter).to receive(:toc?).and_return(true)
          allow(monograph_presenter).to receive(:pdf_ebook_presenter).and_return(pdf_ebook_presenter)
          allow(pdf_ebook_presenter).to receive(:intervals).and_return([instance_double(EBookIntervalPresenter,
                                                                                        title: 'Contents',
                                                                                        level: 1,
                                                                                        cfi: "page=6",
                                                                                        'downloadable?': true),
                                                                        instance_double(EBookIntervalPresenter,
                                                                                        title: 'Foreword | Timmy B. Wright',
                                                                                        level: 1, cfi: 'page=8',
                                                                                        'downloadable?': true)])
        end

        context 'user is authed' do
          before do
            allow_any_instance_of(Auth).to receive(:actor_unauthorized?).and_return(false)
            render
          end

          it 'links ToC entries' do
            debug_puts subject.to_s
            is_expected.to match 'toc-link'
          end
        end

        context 'user is not authed' do
          before do
            allow_any_instance_of(Auth).to receive(:actor_unauthorized?).and_return(true)
            render
          end

          it 'does not link ToC entries' do
            debug_puts subject.to_s
            is_expected.to_not match 'toc-link'
          end
        end
      end
    end
  end
end
