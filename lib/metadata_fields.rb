# frozen_string_literal: true

# as this file lives outside the Rails app directory structure, this definitions file needs to be force-loaded
I18n.load_path += Dir[Rails.root.join("config", "locales", "heliotrope.en.yml").to_s]

# something to note is that the multivalued :yes/:no values mirror the model, such that assignment will work properly as a scalar or array...
# :yes_split means that this is a field we actually want to *use* as multivalued, and so will split the CSV field on semicolons to do so
# :yes_multiline means we only want to use <fieldname>.first of a multi-valued field to store all our values, which will be separated with a new line within that string

# ActiveFedora fields not really 'settable' by users, needed in the import-export-edit-import cycle
ADMIN_METADATA_FIELDS ||=
  [
    { object: :universal, field_name: 'NOID', metadata_name: 'id', required: true, multivalued: :no, description: I18n.t('csv.descriptions.id') },
    { object: :file_set, field_name: 'File Name', metadata_name: 'label', required: true, multivalued: :no, description: I18n.t('csv.descriptions.label') },
    { object: :universal, field_name: 'Link', metadata_name: 'url', required: true, multivalued: :no, description: I18n.t('csv.descriptions.url') },
    { object: :file_set, field_name: 'Embed Code', multivalued: :no, description: I18n.t('csv.descriptions.embed_code') },
    { object: :universal, field_name: 'Date Uploaded', metadata_name: 'date_uploaded', required: true, multivalued: :no, description: I18n.t('csv.descriptions.date_uploaded') },
    { object: :universal, field_name: 'Date Modified', metadata_name: 'date_modified', required: true, multivalued: :no, description: I18n.t('csv.descriptions.date_modified') },
  ].freeze

# ActiveFedora fields we allow folks to set
METADATA_FIELDS ||=
  [
    { object: :universal, field_name: 'Title', metadata_name: 'title', required: true, multivalued: :yes, newlines: false, description: I18n.t('csv.descriptions.title') },
    { object: :file_set, field_name: 'Resource Type', metadata_name: 'resource_type', required: true, multivalued: :yes, description: I18n.t('csv.descriptions.resource_type') },
    { object: :file_set, field_name: 'External Resource URL', metadata_name: 'external_resource_url', required: false, multivalued: :no, description: I18n.t('csv.descriptions.external_resource_url') },
    { object: :file_set, field_name: 'Caption', metadata_name: 'caption', required: true, multivalued: :yes, description: I18n.t('csv.descriptions.caption') },
    { object: :file_set, field_name: 'Alternative Text', metadata_name: 'alt_text', required: true, multivalued: :yes, description: I18n.t('csv.descriptions.alt_text') },
    { object: :universal, field_name: 'Rightsholder', metadata_name: 'rightsholder', required: true, multivalued: :no, description: I18n.t('csv.descriptions.rightsholder') },
    { object: :file_set, field_name: 'Copyright Status', metadata_name: 'copyright_status', required: true, multivalued: :no, description: I18n.t('csv.descriptions.copyright_status') },
    { object: :monograph, field_name: 'Open Access?', metadata_name: 'open_access', required: false, multivalued: :no, description: I18n.t('csv.descriptions.open_access') },
    { object: :monograph, field_name: 'Funder', metadata_name: 'funder', required: false, multivalued: :no, description: I18n.t('csv.descriptions.funder') },
    { object: :monograph, field_name: 'Funder Display', metadata_name: 'funder_display', required: false, multivalued: :no, description: I18n.t('csv.descriptions.funder_display') },
    { object: :file_set, field_name: 'Allow Fullscreen Display?', metadata_name: 'allow_hi_res', required: true, multivalued: :no, description: I18n.t('csv.descriptions.allow_hi_res') },
    { object: :file_set, field_name: 'Allow Download?', metadata_name: 'allow_download', required: true, multivalued: :no, description: I18n.t('csv.descriptions.allow_download') },
    { object: :file_set, field_name: 'Rights Granted', metadata_name: 'rights_granted', required: false, multivalued: :no, description: I18n.t('csv.descriptions.rights_granted') },
    { object: :universal, field_name: 'CC License', metadata_name: 'license', required: false, multivalued: :yes, description: I18n.t('csv.descriptions.license') },
    { object: :file_set, field_name: 'Permissions Expiration Date', metadata_name: 'permissions_expiration_date', required: false, multivalued: :no, date_format: true, description: I18n.t('csv.descriptions.permissions_expiration_date') },
    { object: :file_set, field_name: 'After Expiration: Allow Display?', metadata_name: 'allow_display_after_expiration', required: false, multivalued: :no, description: I18n.t('csv.descriptions.allow_display_after_expiration') },
    { object: :file_set, field_name: 'After Expiration: Allow Download?', metadata_name: 'allow_download_after_expiration', required: false, multivalued: :no, description: I18n.t('csv.descriptions.allow_download_after_expiration') },
    { object: :file_set, field_name: 'Credit Line', metadata_name: 'credit_line', required: false, multivalued: :no, description: I18n.t('csv.descriptions.credit_line') },
    { object: :universal, field_name: 'Holding Contact', metadata_name: 'holding_contact', required: false, multivalued: :no, description: I18n.t('csv.descriptions.holding_contact') },
    { object: :file_set, field_name: 'Exclusive to Fulcrum', metadata_name: 'exclusive_to_platform', required: false, multivalued: :no, description: I18n.t('csv.descriptions.exclusive_to_platform') },
    { object: :universal, field_name: 'Identifier(s)', metadata_name: 'identifier', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.identifier') },
    { object: :file_set, field_name: 'Content Type', metadata_name: 'content_type', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.content_type') },
    { object: :universal, field_name: 'Creator(s)', metadata_name: 'creator', required: false, multivalued: :yes_multiline, description: I18n.t('csv.descriptions.creator') },
    { object: :universal, field_name: 'Additional Creator(s)', metadata_name: 'contributor', required: false, multivalued: :yes_multiline, description: I18n.t('csv.descriptions.contributor') },
    { object: :monograph, field_name: 'Creator Display', metadata_name: 'creator_display', required: false, multivalued: :no, description: I18n.t('csv.descriptions.creator_display') },
    { object: :file_set, field_name: 'Sort Date', metadata_name: 'sort_date', required: false, multivalued: :no, date_format: true, description: I18n.t('csv.descriptions.sort_date') },
    { object: :file_set, field_name: 'Display Date', metadata_name: 'display_date', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.display_date') },
    { object: :universal, field_name: 'Description', metadata_name: 'description', required: false, multivalued: :yes, description: I18n.t('csv.descriptions.description') },
    { object: :universal, field_name: 'Content Warning', metadata_name: 'content_warning', required: false, multivalued: :no, description: I18n.t('csv.descriptions.content_warning') },
    { object: :universal, field_name: 'Content Warning Information', metadata_name: 'content_warning_information', required: false, multivalued: :no, description: I18n.t('csv.descriptions.content_warning_information') },
    { object: :monograph, field_name: 'Publisher', metadata_name: 'publisher', multivalued: :yes, description: I18n.t('csv.descriptions.publisher') },
    { object: :monograph, field_name: 'Subject', metadata_name: 'subject', multivalued: :yes_split, description: I18n.t('csv.descriptions.subject') },
    { object: :monograph, field_name: 'ISBN(s)', metadata_name: 'isbn', multivalued: :yes_split, description: I18n.t('csv.descriptions.isbn') },
    { object: :monograph, field_name: 'Buy Book URL', metadata_name: 'buy_url', multivalued: :yes, description: I18n.t('csv.descriptions.buy_url') },
    { object: :monograph, field_name: 'Pub Year', metadata_name: 'date_created', multivalued: :yes, description: I18n.t('csv.descriptions.date_created') },
    { object: :monograph, field_name: 'Pub Location', metadata_name: 'location', multivalued: :no, description: I18n.t('csv.descriptions.location') },
    { object: :monograph, field_name: 'Series', metadata_name: 'series', multivalued: :yes_split, description: I18n.t('csv.descriptions.series') },
    { object: :monograph, field_name: 'Edition Name', metadata_name: 'edition_name', multivalued: :no, description: I18n.t('csv.descriptions.edition_name') },
    { object: :monograph, field_name: 'Previous Edition', metadata_name: 'previous_edition', multivalued: :no, description: I18n.t('csv.descriptions.previous_edition') },
    { object: :monograph, field_name: 'Next Edition', metadata_name: 'next_edition', multivalued: :no, description: I18n.t('csv.descriptions.next_edition') },
    { object: :universal, field_name: 'Keywords', metadata_name: 'keyword', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.keyword') },
    { object: :monograph, field_name: 'Section Titles', metadata_name: 'section_titles', required: false, multivalued: :no, description: I18n.t('csv.descriptions.section_titles') },
    { object: :file_set, field_name: 'Section', metadata_name: 'section_title', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.section_title') },
    { object: :universal, field_name: 'Language', metadata_name: 'language', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.language') },
    { object: :file_set, field_name: 'Transcript', metadata_name: 'transcript', required: false, multivalued: :no, description: I18n.t('csv.descriptions.transcript') },
    { object: :file_set, field_name: 'Translation', metadata_name: 'translation', required: false, multivalued: :yes, description: I18n.t('csv.descriptions.translation') },
    { object: :universal, field_name: 'DOI', metadata_name: 'doi', required: false, multivalued: :no, description: I18n.t('csv.descriptions.doi') },
    { object: :universal, field_name: 'Handle', metadata_name: 'hdl', required: false, multivalued: :no, description: I18n.t('csv.descriptions.hdl') },
    { object: :file_set, field_name: 'Closed Captions', metadata_name: 'closed_captions', required: false, multivalued: :yes, description: I18n.t('csv.descriptions.closed_captions') },
    { object: :file_set, field_name: 'Visual Descriptions', metadata_name: 'visual_descriptions', required: false, multivalued: :yes, description: I18n.t('csv.descriptions.visual_descriptions') },
    { object: :universal, field_name: 'Tombstone?', metadata_name: 'tombstone', required: false, multivalued: :no, description: I18n.t('csv.descriptions.tombstone') },
    { object: :universal, field_name: 'Tombstone Message', metadata_name: 'tombstone_message', required: false, multivalued: :no, description: I18n.t('csv.descriptions.tombstone_message') },
    { object: :monograph, field_name: 'Volume', metadata_name: 'volume', required: false, multivalued: :no, description: I18n.t('csv.descriptions.volume') },
    { object: :monograph, field_name: 'OCLC Work Identifier', metadata_name: 'oclc_owi', required: false, multivalued: :no, description: I18n.t('csv.descriptions.oclc_owi') },
    { object: :monograph, field_name: 'Copyright Year', metadata_name: 'copyright_year', required: false, multivalued: :no, description: I18n.t('csv.descriptions.copyright_year') },
    { object: :monograph, field_name: 'Award(s)', metadata_name: 'award', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.award') },
    { object: :file_set, field_name: 'Article Title', metadata_name: 'article_title', required: false, multivalued: :no, description: I18n.t('csv.descriptions.article_title') },
    { object: :file_set, field_name: 'Article Creator(s)', metadata_name: 'article_creator', required: false, multivalued: :yes_multiline, description: I18n.t('csv.descriptions.article_creator') },
    { object: :file_set, field_name: 'Article Permalink', metadata_name: 'article_permalink', required: false, multivalued: :no, description: I18n.t('csv.descriptions.article_permalink') },
    { object: :file_set, field_name: 'Article Volume', metadata_name: 'article_volume', required: false, multivalued: :no, description: I18n.t('csv.descriptions.article_volume') },
    { object: :file_set, field_name: 'Article Issue', metadata_name: 'article_issue', required: false, multivalued: :no, description: I18n.t('csv.descriptions.article_issue') },
    { object: :file_set, field_name: 'Article Display Date', metadata_name: 'article_display_date', required: false, multivalued: :no, description: I18n.t('csv.descriptions.article_display_date') },
    { object: :monograph, field_name: 'Press', metadata_name: 'press', multivalued: :no, description: I18n.t('csv.descriptions.press') },
    { object: :universal, field_name: 'Published?', metadata_name: 'visibility', multivalued: :no, description: I18n.t('csv.descriptions.published') },
    { object: :universal, field_name: 'Date Published on Fulcrum', metadata_name: 'date_published', multivalued: :yes, description: I18n.t('csv.descriptions.date_published') },
].freeze

# Any fields related to "representative" relationships between FileSets and their parent Monograph
FILE_SET_FLAG_FIELDS ||=
  [
    { object: :file_set, field_name: 'Representative Kind', metadata_name: 'representative_kind', required: false, multivalued: :no, description: I18n.t('csv.descriptions.representative_kind') }
  ].freeze

MONO_FILENAME_FLAG ||= '://:MONOGRAPH://:'

# any renamed "field names", i.e. CSV header row values can go here, this enables the importer to work on older...
# exported "manifest" CSV files or old versions of the FMSLs. Alternates like singular/plural versions of field...
# names could also be added here if desired. Each hash entry should be in this order:
# 'Alternative/Old Field Name' => 'Actual Field Name (as seen in the hashes above)'
FIELD_NAME_MAP ||= { 'Copyright Holder' => 'Rightsholder' }
