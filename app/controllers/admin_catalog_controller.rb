# frozen_string_literal: true

# The admin catalog is a full-catalog endpoint. It is a *sibling* of
# CatalogController (both inherit ApplicationCatalogController and share
# FullCatalogBehavior) rather than a subclass, so it does not inherit the public
# catalog's facets/OAI and — importantly — has its own platform-admin gate whose
# lifetime is independent of the public catalog's temporary one.
#
# Via FullCatalogBehavior it gets the CatalogSearchBuilder (default results
# include Monographs from all presses plus FileSets) and the shared index/search
# fields. On top of that it declares the facets administrators want to filter on:
#   1. Facets from PressCatalogController (press-specific conditional logic removed)
#   2. Facets from MonographCatalogController
#   3. New admin-only facets: e.g. a "Subdomain" facet (press_sim, also indexed onto
#      FileSets from their parent Monograph), a "Published?" facet
#      (visibility_ssi), and an "Object Type" facet (has_model_ssim).
class AdminCatalogController < ApplicationCatalogController
  include FullCatalogBehavior
  include PlatformAdminGate

  configure_blacklight do |config| # rubocop:disable Metrics/BlockLength
    # Add per-result admin tools (edit/show links + permission badge) for every
    # result, rendered via app/views/admin_catalog/_admin_tools.html.erb.
    config.index.partials += [:admin_tools]

    # --- Admin-only: Object Type (ungrouped, always first) ---
    config.add_facet_field 'has_model_ssim', label: 'Object Type', limit: 10, url_method: :facet_url_helper

    # --- Universal group (object: :universal in METADATA_FIELDS, or platform-wide admin fields) ---
    # Author → metadata_name: 'creator', object: :universal
    config.add_facet_field 'creator_sim', label: 'Author/Creator', group: 'Universal', limit: 5, url_method: :facet_url_helper
    # Contributor → metadata_name: 'contributor', object: :universal
    config.add_facet_field solr_name('contributor', :facetable), label: 'Contributor', group: 'Universal', show: false
    # Creator Role — not in METADATA_FIELDS but platform-wide in scope
    config.add_facet_field solr_name('primary_creator_role', :facetable), label: 'Creator Role', group: 'Universal',
                           show: false
    # Keyword → metadata_name: 'keyword', object: :universal
    config.add_facet_field solr_name('keyword', :facetable), label: 'Keyword', group: 'Universal', limit: 5,
                           more_limit: 1000, url_method: :facet_url_helper, partial: 'case_insensitive_sort_facet'
    # Published? → metadata_name: 'visibility', object: :universal
    config.add_facet_field 'visibility_ssi', label: 'Published?', group: 'Universal', url_method: :facet_url_helper
    # Subdomain — not in METADATA_FIELDS but press/monograph-level concept
    # press_sim: Monographs index via `press`; FileSetIndexer copies it onto FileSets too.
    config.add_facet_field 'press_sim', label: 'Subdomain', group: 'Universal', limit: 10,
                           url_method: :facet_url_helper
    # Year — not in METADATA_FIELDS but platform-wide in scope
    config.add_facet_field solr_name('search_year', :facetable), label: 'Year', group: 'Universal', limit: 5,
                           url_method: :facet_url_helper

    # --- Monograph group (object: :monograph in METADATA_FIELDS, or press-level admin fields) ---
    # Author Place of Origin → metadata_name: 'author_place_of_origin', object: :monograph
    config.add_facet_field 'author_place_of_origin_sim', label: 'Author Place of Origin', group: 'Monograph', limit: 5,
                           url_method: :facet_url_helper
    # Collection → metadata_name: 'collection', object: :monograph
    config.add_facet_field 'collection_sim', label: 'Collection', group: 'Monograph', limit: 5,
                           url_method: :facet_url_helper
    # Funder → metadata_name: 'funder', object: :monograph
    config.add_facet_field 'funder_sim', label: 'Funder', group: 'Monograph', limit: 5, url_method: :facet_url_helper
    # Products — not in METADATA_FIELDS but press/monograph-level concept
    config.add_facet_field 'product_names_sim', label: 'Products', group: 'Monograph', limit: 5
    # Publisher → metadata_name: 'publisher', object: :monograph
    config.add_facet_field 'publisher_sim', label: 'Publisher', group: 'Monograph', limit: 5,
                           url_method: :facet_url_helper
    # Reader Ebook Format — not in METADATA_FIELDS but a file-level format concept
    config.add_facet_field 'reader_ebook_format_sim', label: 'Reader Ebook Format', group: 'Monograph', limit: false
    # Series → metadata_name: 'series', object: :monograph
    config.add_facet_field 'series_sim', label: 'Series', group: 'Monograph', limit: 5, url_method: :facet_url_helper
    # Source — not in METADATA_FIELDS but press/monograph-level concept
    config.add_facet_field 'press_name_sim', label: 'Source', group: 'Monograph', limit: 5,
                           url_method: :facet_url_helper
    # Subject → metadata_name: 'subject', object: :monograph
    config.add_facet_field 'subject_sim', label: 'Subject', group: 'Monograph', limit: 10,
                           url_method: :facet_url_helper

    # --- File Set group (object: :file_set in METADATA_FIELDS, or file/format-level fields) ---
    # Content → metadata_name: 'content_type', object: :file_set
    config.add_facet_field solr_name('content_type', :facetable), label: 'Content', group: 'File Set', show: false
    # Exclusivity → metadata_name: 'exclusive_to_platform', object: :file_set
    config.add_facet_field solr_name('exclusive_to_platform', :facetable), label: 'Exclusivity', group: 'File Set',
                           query: { exclusive_to_platform: { label: 'Exclusive to Fulcrum', fq: "#{solr_name('exclusive_to_platform', :facetable)}:yes" } }
    # Format → metadata_name: 'resource_type', object: :file_set
    config.add_facet_field solr_name('resource_type', :facetable), label: 'Format', group: 'File Set', limit: 5,
                           url_method: :facet_url_helper
    # Section → metadata_name: 'section_title', object: :file_set
    config.add_facet_field solr_name('section_title', :facetable), label: 'Section', group: 'File Set',
                           url_method: :facet_url_helper

    # --- Ebook Accessibility group ---
    # Screen Reader Friendly — derived field: 'yes'/'no'/'unknown' for EPUBs, 'yes'/'no, but...'/'no' for PDFs
    config.add_facet_field 'epub_a11y_screen_reader_friendly_ssi', label: 'EPUB Screen Reader Friendly',
                           group: 'Ebook Accessibility', limit: false
    config.add_facet_field 'pdf_a11y_screen_reader_friendly_ssi', label: 'PDF Screen Reader Friendly',
                           group: 'Ebook Accessibility', limit: false
    # Conformance — dcterms:conformsTo for EPUBs; passing standard(s) for PDFs
    config.add_facet_field 'epub_a11y_conforms_to_ssi', label: 'EPUB Conformance',
                           group: 'Ebook Accessibility', limit: 5, url_method: :facet_url_helper
    config.add_facet_field 'pdf_a11y_conforms_to_ssi', label: 'PDF Conformance',
                           group: 'Ebook Accessibility', limit: 5, url_method: :facet_url_helper
    # Access Mode — schema:accessMode
    config.add_facet_field 'epub_a11y_access_mode_ssim', label: 'EPUB Access Mode',
                           group: 'Ebook Accessibility', limit: false
    config.add_facet_field 'pdf_a11y_access_mode_ssim', label: 'PDF Access Mode',
                           group: 'Ebook Accessibility', limit: false
    # Sufficient Access Mode — schema:accessModeSufficient
    config.add_facet_field 'epub_a11y_access_mode_sufficient_ssim', label: 'EPUB Sufficient Access Mode',
                           group: 'Ebook Accessibility', limit: false
    config.add_facet_field 'pdf_a11y_access_mode_sufficient_ssim', label: 'PDF Sufficient Access Mode',
                           group: 'Ebook Accessibility', limit: false

    config.add_facet_fields_to_solr_request!
  end
end
