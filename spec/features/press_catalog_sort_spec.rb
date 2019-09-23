# frozen_string_literal: true

require 'rails_helper'

describe 'Press catalog sort' do
  context 'Monograph results set end-to-end' do
    before do
      create(:press, subdomain: 'sort_press1')
      create(:public_monograph,
             press: 'sort_press1',
             title: ['silverfish'],
             date_uploaded: DateTime.new(2018, 11, 3, 4, 5, 0, '+0'),
             creator: ["Hopeful, Barry"],
             date_created: ['20180101'])

      create(:public_monograph,
             press: 'sort_press1',
             title: ['Cormorant'],
             date_uploaded: DateTime.new(2018, 10, 3, 4, 5, 0, '+0'),
             creator: ['Zidane, "Headbutt"'],
             date_created: ['2015-01-01T00:00'])

      create(:public_monograph,
             press: 'sort_press1',
             title: ['Zebra'],
             date_uploaded: DateTime.new(2018, 12, 3, 4, 5, 0, '+0'),
             creator: ["Andrée, Renée"],
             date_created: ['2013MMDD'])

      create(:public_monograph,
             press: 'sort_press1',
             title: ['aardvark'],
             date_uploaded: DateTime.new(2018, 7, 3, 4, 5, 0, '+0'),
             creator: ["Andrea, Rita"],
             date_created: ['2017'])

      create(:public_monograph,
             press: 'sort_press1',
             title: ['Manatee'],
             date_uploaded: DateTime.new(2018, 8, 3, 4, 5, 0, '+0'),
             creator: ["Gulliver, Guy"],
             date_created: ['2016/05/05'])

      create(:public_monograph,
             press: 'sort_press1',
             title: ['baboon'],
             date_uploaded: DateTime.new(2018, 9, 3, 4, 5, 0, '+0'),
             creator: ["andrew, ruth"],
             date_created: ['2014'])

      visit "/sort_press1"
    end

    it 'is sorted by "Date Added (Newest First)" by default' do
      assert_equal page.all('.documentHeader .index_title a').map(&:text), ['Zebra',
                                                                            'silverfish',
                                                                            'Cormorant',
                                                                            'baboon',
                                                                            'Manatee',
                                                                            'aardvark']
    end

    it 'is sortable by "Author (A-Z)"' do
      click_link 'Author (A-Z)'
      # names reversed by `authors` method in MonographPresenter
      assert_equal page.all('.document .thumbnail .caption p').map(&:text), ['Rita Andrea',
                                                                             'Renée Andrée',
                                                                             'ruth andrew',
                                                                             'Guy Gulliver',
                                                                             'Barry Hopeful',
                                                                             '"Headbutt" Zidane']
    end

    it 'is sortable by "Author (Z-A)"' do
      click_link 'Author (Z-A)'
      # names reversed by `authors` method in MonographPresenter
      assert_equal page.all('.document .thumbnail .caption p').map(&:text), ['"Headbutt" Zidane',
                                                                             'Barry Hopeful',
                                                                             'Guy Gulliver',
                                                                             'ruth andrew',
                                                                             'Renée Andrée',
                                                                             'Rita Andrea']
    end

    it 'is sortable by "Publication Date (Newest First)"' do
      click_link 'Publication Date (Newest First)'
      # using corresponding titles to check position as pub year isn't shown in results page (or set here)
      assert_equal page.all('.documentHeader .index_title a').map(&:text), ['silverfish',
                                                                            'aardvark',
                                                                            'Manatee',
                                                                            'Cormorant',
                                                                            'baboon',
                                                                            'Zebra']
    end

    it 'is sortable by "Publication Date (Oldest First)"' do
      click_link 'Publication Date (Oldest First)'
      # using corresponding titles to check position as pub year isn't shown in results page (or set here)
      assert_equal page.all('.documentHeader .index_title a').map(&:text), ['Zebra',
                                                                            'baboon',
                                                                            'Cormorant',
                                                                            'Manatee',
                                                                            'aardvark',
                                                                            'silverfish']
    end

    it 'is sortable by "Title (A-Z)"' do
      click_link 'Title (A-Z)'
      assert_equal page.all('.documentHeader .index_title a').map(&:text), ['aardvark',
                                                                            'baboon',
                                                                            'Cormorant',
                                                                            'Manatee',
                                                                            'silverfish',
                                                                            'Zebra']
    end

    it 'is sortable by "Title (Z-A)"' do
      click_link 'Title (Z-A)'
      assert_equal page.all('.documentHeader .index_title a').map(&:text), ['Zebra',
                                                                            'silverfish',
                                                                            'Manatee',
                                                                            'Cormorant',
                                                                            'baboon',
                                                                            'aardvark']
    end
  end

  context 'Monograph results set using Solr Docs' do
    # note: The spec above is more appropriate as it incorporates manipulation being done in indexer/presenter, like...
    # sort normalization. I'm doing this additional pure-Solr test for fun, but also because:
    # - if we ever need to test sorting on immutable Fedora values like system_create or system_modified they can be tested in this manner also
    # - it's an excuse to experiment with the minimum Solr fields required by these Blacklight views

    let(:mono_doc_1) {
      ::SolrDocument.new(
        # note: the use of dynamicField in schema.xml takes care of field configuration like cardinality (multiValued)
        # need these 4 fields to get this doc to show on catalog page
        id: '111111111',
        has_model_ssim: 'Monograph',
        press_sim: "sort_press2",
        read_access_group_ssim: "public",
        # inexact dynamicField usage summary: *_si for sorting, *_tesim for display, *_dtsi for sortable date
        # note: you can never sort by multi-valued Solr fields, e.g. with an 'm' in the suffix per schema.xml
        title_tesim: 'silverfish',
        title_si: 'silverfish',
        creator_tesim: ['Thomas, John'],
        creator_full_name_si: 'Thomas, John',
        date_created_si: '201516', # sortable publication year, stripped of non-numeric characters (say, 'c.2015-16?')
        date_uploaded_dtsi: '2001-02-25T15:59:47Z' # default sort field
      )
    }
    let(:mono_doc_2) {
      ::SolrDocument.new(
        id: '222222222',
        has_model_ssim: 'Monograph',
        press_sim: "sort_press2",
        read_access_group_ssim: "public",
        title_tesim: 'Cormorant',
        title_si: 'cormorant', # this is downcased on indexing, otherwise sort will have caps first
        creator_tesim: 'Hopeful, Barry',
        creator_full_name_si: 'Hopeful, Barry',
        date_created_si: '2012-02-21T17:03:54Z', # terrible publication year entry, should still alpha sort OK
        date_uploaded_dtsi: '1999-01-25T15:59:47Z'
      )
    }
    let(:mono_doc_3) {
      ::SolrDocument.new(
        id: '333333333',
        has_model_ssim: 'Monograph',
        press_sim: "sort_press2",
        read_access_group_ssim: "public",
        title_tesim: 'Zebra',
        title_si: 'zebra', # this is downcased on indexing, otherwise sort will have caps first
        creator_tesim: 'Quinn, Smiley',
        creator_full_name_si: 'Quinn, Smiley',
        date_created_si: '2014',
        date_uploaded_dtsi: '2011-06-25T15:59:47Z'
      )
    }
    let(:mono_doc_4) {
      ::SolrDocument.new(
        id: '444444444',
        has_model_ssim: 'Monograph',
        press_sim: "sort_press2",
        read_access_group_ssim: "public",
        title_tesim: 'aardvark',
        title_si: 'aardvark',
        creator_tesim: 'Gulliver, Guy',
        creator_full_name_si: 'Gulliver, Guy',
        date_created_si: '2013?',
        date_uploaded_dtsi: '2018-03-25T15:59:47Z'
      )
    }
    let(:mono_doc_5) {
      ::SolrDocument.new(
        id: '555555555',
        has_model_ssim: 'Monograph',
        press_sim: "sort_press2",
        read_access_group_ssim: "public",
        title_tesim: 'Manatee',
        title_si: 'manatee', # this is downcased on indexing, otherwise sort will have caps first
        creator_tesim: 'Rodrigues, Maria',
        creator_full_name_si: 'Rodrigues, Maria',
        date_created_si: 'c2016',
        date_uploaded_dtsi: '2017-04-25T15:59:47Z'
      )
    }
    let(:mono_doc_6) {
      ::SolrDocument.new(
        id: '666666666',
        has_model_ssim: 'Monograph',
        press_sim: "sort_press2",
        read_access_group_ssim: "public",
        title_tesim: 'baboon',
        title_si: 'baboon',
        creator_tesim: 'Smith, Jim',
        creator_full_name_si: 'Smith, Jim',
        date_created_si: '2011',
        date_uploaded_dtsi: '2014-05-25T15:59:47Z'
      )
    }

    before do
      create(:press, subdomain: 'sort_press2')
      ActiveFedora::SolrService.add([mono_doc_1.to_h,
                                     mono_doc_2.to_h,
                                     mono_doc_3.to_h,
                                     mono_doc_4.to_h,
                                     mono_doc_5.to_h,
                                     mono_doc_6.to_h])
      ActiveFedora::SolrService.commit
      visit "/sort_press2"
    end

    it 'is sorted by "Date Added (Newest First)" by default' do
      assert_equal page.all('.documentHeader .index_title a').map(&:text), ['aardvark',
                                                                            'Manatee',
                                                                            'baboon',
                                                                            'Zebra',
                                                                            'silverfish',
                                                                            'Cormorant']
    end

    it 'is sortable by "Author (A-Z)"' do
      click_link 'Author (A-Z)'
      # names reversed by `authors` method in MonographPresenter
      assert_equal page.all('.document .thumbnail .caption p').map(&:text), ['Guy Gulliver',
                                                                             'Barry Hopeful',
                                                                             'Smiley Quinn',
                                                                             'Maria Rodrigues',
                                                                             'Jim Smith',
                                                                             'John Thomas']
    end

    it 'is sortable by "Author (Z-A)"' do
      click_link 'Author (Z-A)'
      # names reversed by `authors` method in MonographPresenter
      assert_equal page.all('.document .thumbnail .caption p').map(&:text), ['John Thomas',
                                                                             'Jim Smith',
                                                                             'Maria Rodrigues',
                                                                             'Smiley Quinn',
                                                                             'Barry Hopeful',
                                                                             'Guy Gulliver']
    end

    it 'is sortable by "Publication Date (Newest First)"' do
      click_link 'Publication Date (Newest First)'
      # using corresponding titles to check position as pub year isn't shown in results page (or set here)
      assert_equal page.all('.documentHeader .index_title a').map(&:text), ['Manatee',
                                                                            'silverfish',
                                                                            'Zebra',
                                                                            'aardvark',
                                                                            'Cormorant',
                                                                            'baboon']
    end

    it 'is sortable by "Publication Date (Oldest First)"' do
      click_link 'Publication Date (Oldest First)'
      # using corresponding titles to check position as pub year isn't shown in results page (or set here)
      assert_equal page.all('.documentHeader .index_title a').map(&:text), ['baboon',
                                                                            'Cormorant',
                                                                            'aardvark',
                                                                            'Zebra',
                                                                            'silverfish',
                                                                            'Manatee']
    end

    it 'is sortable by "Title (A-Z)"' do
      click_link 'Title (A-Z)'
      assert_equal page.all('.documentHeader .index_title a').map(&:text), ['aardvark',
                                                                            'baboon',
                                                                            'Cormorant',
                                                                            'Manatee',
                                                                            'silverfish',
                                                                            'Zebra']
    end

    it 'is sortable by "Title (Z-A)"' do
      click_link 'Title (Z-A)'
      assert_equal page.all('.documentHeader .index_title a').map(&:text), ['Zebra',
                                                                            'silverfish',
                                                                            'Manatee',
                                                                            'Cormorant',
                                                                            'baboon',
                                                                            'aardvark']
    end
  end
end
