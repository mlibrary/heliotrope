# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "monograph_catalog/index.html.erb", type: :view do
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
  let(:monograph_presenter) { build(:monograph_presenter) }

  before do
    stub_template "catalog/_search_sidebar" => "<!-- render-template-catalog/_search_sidebar -->"
    stub_template "catalog/_search_results" => "<!-- render-template-catalog/_search_results -->"
    assign(:monograph_presenter, monograph_presenter)
    allow(view).to receive(:t).with(any_args) { |value| value }
    allow(monograph_presenter).to receive(:date_uploaded).and_return(DateTime.now)
  end

  describe 'provide: page_title' do
    subject { view.view_flow.content[:page_title] }
    let(:page_title) { 'PAGE-TITLE' }
    before do
      allow(monograph_presenter).to receive(:title).and_return(page_title)
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
    let(:subdomain) { 'SUBDOMAIN' }
    let!(:press) { create(:press, subdomain: subdomain) }
    before do
      allow(monograph_presenter).to receive(:page_title).and_return(page_title)
      allow(monograph_presenter).to receive(:subdomain).and_return(subdomain)
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
      let(:editors) { "EDITORS" }

      context 'default' do
        before do
          monograph_presenter.instance_eval('undef :monograph_coins_title')
          render
        end
        it do
          debug_puts subject.to_s
          is_expected.not_to be_empty
          is_expected.not_to match(/<span.*?class=\"Z3988\".*?title=\".*?".*?>.*?<\/span>/m)
          is_expected.not_to match t('.show_page_button')
          is_expected.not_to match t('.edit_page_button')
          is_expected.not_to match authors
          is_expected.not_to match t('.edited_by')
          is_expected.not_to match(/<div.*?class=\"isbn\".*?>.*?<\/div>/m)
          is_expected.not_to match t('isbn')
          is_expected.not_to match t('isbn_paper')
          is_expected.not_to match t('isbn_ebook')
          is_expected.not_to match t('.buy')
          is_expected.not_to match t('.buy_book')
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
          is_expected.to match(/<span.*?class=\"Z3988\".*?title=\"#{monograph_coins_title}\".*?>.*?<\/span>/m)
        end
      end

      context 'can? :edit' do
        before do
          allow(view).to receive(:can?).and_return(true)
          render
        end
        it do
          debug_puts subject.to_s
          is_expected.to match t('.show_page_button')
          is_expected.to match t('.edit_page_button')
        end
      end

      context 'authors?' do
        before do
          allow(monograph_presenter).to receive(:authors?).and_return(true)
          allow(monograph_presenter).to receive(:authors).and_return(authors)
          render
        end
        it do
          debug_puts subject.to_s
          is_expected.to match authors
        end
      end

      context 'editors?' do
        before do
          allow(monograph_presenter).to receive(:editors?).and_return(true)
          allow(monograph_presenter).to receive(:editors).and_return(editors)
          render
        end
        it do
          debug_puts subject.to_s
          is_expected.to match t('.edited_by')
        end
      end

      context 'pageviews' do
        before do
          allow(monograph_presenter).to receive(:pageviews).and_return("PAGEVIEWS")
          render
        end
        it do
          debug_puts subject.to_s
          is_expected.to match t('pageviews_html')
        end
      end

      context 'isbn (a.k.a. isbn_hardcover)' do
        before do
          allow(monograph_presenter).to receive(:isbn).and_return("ISBN-HARDCOVER")
          render
        end
        it do
          debug_puts subject.to_s
          is_expected.to match t('isbn')
          is_expected.to match "ISBN-HARDCOVER"
        end
      end

      context 'isbn_paper' do
        before do
          allow(monograph_presenter).to receive(:isbn_paper).and_return(["ISBN-PAPER"])
          render
        end
        it do
          debug_puts subject.to_s
          is_expected.to match t('isbn_paper')
          is_expected.to match "ISBN-PAPER"
        end
      end

      context 'isbn_ebook?' do
        before do
          allow(monograph_presenter).to receive(:isbn_ebook?).and_return(true)
          allow(monograph_presenter).to receive(:isbn_ebook).and_return(["ISBN-EBOOK"])
          render
        end
        it do
          debug_puts subject.to_s
          is_expected.to match t('isbn_ebook')
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
          is_expected.to match t('.buy')
          is_expected.to match t('.buy_book')
        end
      end

      context 'handle' do
        before do
          allow(monograph_presenter).to receive(:citable_link).and_return(["http://hdl.handle.net/2027/fulcrum.999999999"])
          render
        end
        it do
          debug_puts subject.to_s
          is_expected.to match t('citable_link')
          is_expected.to match "http://hdl.handle.net/2027/fulcrum.999999999"
        end
      end
    end
  end
end
