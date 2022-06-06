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
  let(:presenter) { Hyrax::MonographPresenter.new(solr_doc, current_ability) }
  let(:ebook_download_presenter) { double("ebook_download_presenter") }

  before do
    ActiveFedora::SolrService.add([solr_doc.to_h])
    ActiveFedora::SolrService.commit
    stub_template "catalog/_search_sidebar" => "<!-- render-template-catalog/_search_sidebar -->"
    stub_template "catalog/_search_results" => "<!-- render-template-catalog/_search_results -->"
    assign(:presenter, presenter)
    assign(:ebook_download_presenter, ebook_download_presenter)
    # HELIO-4115 - deactivate stats tabs but keep the code around as inspiration for the next solution
    # assign(:stats_graph_data, '[{"label":"Total Pageviews","data":[]}]')
    # assign(:pageviews, 0)
    allow(view).to receive(:t).with(any_args) { |value| value }
    allow(presenter).to receive(:date_uploaded).and_return(DateTime.now)
    allow(presenter).to receive(:creator).and_return([])
    allow(ebook_download_presenter).to receive(:downloadable_ebooks?).and_return(false)
  end

  describe 'provide: page_title' do
    subject { view.view_flow.content[:page_title] }

    let(:page_title) { 'PAGE-TITLE' }

    before do
      allow(presenter).to receive(:page_title).and_return(page_title)
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
      allow(presenter).to receive(:title).and_return(page_title)
      allow(presenter).to receive(:subdomain).and_return(subdomain)
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
    before { allow(presenter).to receive(:epub?).and_return(false) }

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
          presenter.instance_eval('undef :monograph_coins_title')
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
          allow(presenter).to receive(:monograph_coins_title?).and_return(true)
          allow(presenter).to receive(:monograph_coins_title).and_return(monograph_coins_title)
          render
        end

        it do
          debug_puts subject.to_s
          is_expected.to match(/<span.*?class="Z3988".*?title="#{monograph_coins_title}".*?>.*?<\/span>/m)
        end
      end

      context 'can? :edit' do
        before do
          allow(view).to receive(:can?).and_return(true)
          render
        end

        it do
          debug_puts subject.to_s
          is_expected.to match t('monograph_catalog.index.show_page_button')
          is_expected.to match t('monograph_catalog.index.edit_page_button')
        end
      end

      # TODO: see https://tools.lib.umich.edu/jira/browse/HELIO-2224
      #
      # context 'pageviews' do
      #   before do
      #     allow(presenter).to receive(:pageviews).and_return("PAGEVIEWS")
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
          allow(presenter).to receive(:isbn).and_return(["ISBN-HARDCOVER", "ISBN-PAPER", "ISBN-EBOOK"])
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
          allow(presenter).to receive(:buy_url?).and_return(true)
          allow(presenter).to receive(:buy_url).and_return("BUY-URL")
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
          allow(presenter).to receive(:citable_link).and_return([HandleNet.url("999999999")])
          render
        end

        it do
          debug_puts subject.to_s
          is_expected.to match t('citable_link')
          is_expected.to match HandleNet.url("999999999")
        end
      end
    end
  end
end
