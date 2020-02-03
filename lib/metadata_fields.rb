# frozen_string_literal: true

# something to note is that the multivalued :yes/:no values mirror the model, such that assignment will work properly as a scalar or array...
# :yes_split means that this is a field we actually want to *use* as multivalued, and so will split the CSV field on semicolons to do so
# :yes_multiline means we only want to use <fieldname>.first of a multi-valued field to store all our values, which will be separated with a new line within that string

# ActiveFedora fields not really 'settable' by users, needed in the import-export-edit-import cycle
ADMIN_METADATA_FIELDS ||=
  [
    { object: :universal, field_name: 'NOID', metadata_name: 'id', required: true, multivalued: :no, description: I18n.t('csv.descriptions.id') },
    { object: :file_set, field_name: 'File Name', metadata_name: 'label', required: true, multivalued: :no, description: I18n.t('csv.descriptions.label') },
    { object: :universal, field_name: 'Link', metadata_name: 'url', required: true, multivalued: :no, description: I18n.t('csv.descriptions.url') },
    { object: :file_set, field_name: 'Embed Code', multivalued: :no, description: I18n.t('csv.descriptions.embed_code') }
  ].freeze

# ActiveFedora fields we allow folks to set
METADATA_FIELDS ||=
  [
    { object: :universal, field_name: 'Title', metadata_name: 'title', required: true, multivalued: :yes, description: I18n.t('csv.descriptions.title') },
    { object: :file_set, field_name: 'Resource Type', metadata_name: 'resource_type', required: true, multivalued: :yes, acceptable_values: ['audio', 'image', 'dataset', 'table', '3D model', 'text', 'video', 'map', 'interactive map'], description: I18n.t('csv.descriptions.resource_type') },
    { object: :file_set, field_name: 'External Resource URL', metadata_name: 'external_resource_url', required: false, multivalued: :no, description: I18n.t('csv.descriptions.external_resource_url') },
    { object: :file_set, field_name: 'Caption', metadata_name: 'caption', required: true, multivalued: :yes, description: I18n.t('csv.descriptions.caption') },
    { object: :file_set, field_name: 'Alternative Text', metadata_name: 'alt_text', required: true, multivalued: :yes, description: I18n.t('csv.descriptions.alt_text') },
    { object: :universal, field_name: 'Copyright Holder', metadata_name: 'copyright_holder', required: true, multivalued: :no, description: I18n.t('csv.descriptions.copyright_holder') },
    { object: :file_set, field_name: 'Copyright Status', metadata_name: 'copyright_status', required: true, multivalued: :no, acceptable_values: ['in-copyright', 'public domain', 'status unknown'], description: I18n.t('csv.descriptions.copyright_status') },
    { object: :monograph, field_name: 'Open Access?', metadata_name: 'open_access', required: false, multivalued: :no, acceptable_values: ['yes', 'no'], description: I18n.t('csv.descriptions.open_access') },
    { object: :monograph, field_name: 'Funder', metadata_name: 'funder', required: false, multivalued: :no, description: I18n.t('csv.descriptions.funder') },
    { object: :file_set, field_name: 'Allow High-Res Display?', metadata_name: 'allow_hi_res', required: true, multivalued: :no, acceptable_values: ['yes', 'no', 'not hosted on the platform'], description: I18n.t('csv.descriptions.allow_hi_res') },
    { object: :file_set, field_name: 'Allow Download?', metadata_name: 'allow_download', required: true, multivalued: :no, acceptable_values: ['yes', 'no', 'not hosted on the platform'], description: I18n.t('csv.descriptions.allow_download') },
    { object: :file_set, field_name: 'Rights Granted', metadata_name: 'rights_granted', required: false, multivalued: :no, description: I18n.t('csv.descriptions.rights_granted') },
    # `Hyrax::LicenseService.new.select_all_options` rather than `select_active_options` as, unlike the UI edit forms, was allow all values here (importing old CC licenses used by partners etc)
    { object: :universal, field_name: 'CC License', metadata_name: 'license', required: false, multivalued: :yes, acceptable_values: Hyrax::LicenseService.new.select_all_options.map { |a| a[1] }, description: I18n.t('csv.descriptions.license') },
    { object: :file_set, field_name: 'Permissions Expiration Date', metadata_name: 'permissions_expiration_date', required: false, multivalued: :no, date_format: true, description: I18n.t('csv.descriptions.permissions_expiration_date') },
    { object: :file_set, field_name: 'After Expiration: Allow Display?', metadata_name: 'allow_display_after_expiration', required: false, multivalued: :no, acceptable_values: ['none', 'high-res', 'low-res', 'not hosted on the platform'], description: I18n.t('csv.descriptions.allow_display_after_expiration') },
    { object: :file_set, field_name: 'After Expiration: Allow Download?', metadata_name: 'allow_download_after_expiration', required: false, multivalued: :no, acceptable_values: ['yes', 'no', 'not hosted on the platform'], description: I18n.t('csv.descriptions.allow_download_after_expiration') },
    { object: :file_set, field_name: 'Credit Line', metadata_name: 'credit_line', required: false, multivalued: :no, description: I18n.t('csv.descriptions.credit_line') },
    { object: :universal, field_name: 'Holding Contact', metadata_name: 'holding_contact', required: false, multivalued: :no, description: I18n.t('csv.descriptions.holding_contact') },
    { object: :file_set, field_name: 'Exclusive to Fulcrum', metadata_name: 'exclusive_to_platform', required: false, multivalued: :no, acceptable_values: ['yes', 'no'], description: I18n.t('csv.descriptions.exclusive_to_platform') },
    { object: :universal, field_name: 'Identifier(s)', metadata_name: 'identifier', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.identifier') },
    { object: :file_set, field_name: 'Content Type', metadata_name: 'content_type', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.content_type') },
    { object: :universal, field_name: 'Creator(s)', metadata_name: 'creator', required: false, multivalued: :yes_multiline, description: I18n.t('csv.descriptions.creator') },
    { object: :universal, field_name: 'Additional Creator(s)', metadata_name: 'contributor', required: false, multivalued: :yes_multiline, description: I18n.t('csv.descriptions.contributor') },
    { object: :monograph, field_name: 'Creator Display', metadata_name: 'creator_display', required: false, multivalued: :no, description: I18n.t('csv.descriptions.creator_display') },
    { object: :file_set, field_name: 'Sort Date', metadata_name: 'sort_date', required: false, multivalued: :no, date_format: true, description: I18n.t('csv.descriptions.sort_date') },
    { object: :file_set, field_name: 'Display Date', metadata_name: 'display_date', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.display_date') },
    { object: :universal, field_name: 'Description', metadata_name: 'description', required: false, multivalued: :yes, description: I18n.t('csv.descriptions.description') },
    { object: :monograph, field_name: 'Publisher', metadata_name: 'publisher', multivalued: :yes, description: I18n.t('csv.descriptions.publisher') },
    { object: :monograph, field_name: 'Subject', metadata_name: 'subject', multivalued: :yes_split, description: I18n.t('csv.descriptions.subject') },
    { object: :monograph, field_name: 'ISBN(s)', metadata_name: 'isbn', multivalued: :yes_split, description: I18n.t('csv.descriptions.isbn') },
    { object: :monograph, field_name: 'Buy Book URL', metadata_name: 'buy_url', multivalued: :yes, description: I18n.t('csv.descriptions.buy_url') },
    { object: :monograph, field_name: 'Pub Year', metadata_name: 'date_created', multivalued: :yes, description: I18n.t('csv.descriptions.date_created') },
    { object: :monograph, field_name: 'Pub Location', metadata_name: 'location', multivalued: :no, description: I18n.t('csv.descriptions.location') },
    { object: :monograph, field_name: 'Series', metadata_name: 'series', multivalued: :yes_split, description: I18n.t('csv.descriptions.series') },
    { object: :file_set, field_name: 'Keywords', metadata_name: 'keywords', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.keywords') },
    { object: :file_set, field_name: 'Section', metadata_name: 'section_title', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.section_title') },
    { object: :file_set, field_name: 'Language', metadata_name: 'language', required: false, multivalued: :yes_split, description: I18n.t('csv.descriptions.language') },
    { object: :file_set, field_name: 'Transcript', metadata_name: 'transcript', required: false, multivalued: :no, description: I18n.t('csv.descriptions.transcript') },
    { object: :file_set, field_name: 'Translation', metadata_name: 'translation', required: false, multivalued: :yes, description: I18n.t('csv.descriptions.translation') },
    { object: :universal, field_name: 'DOI', metadata_name: 'doi', required: false, multivalued: :no, description: I18n.t('csv.descriptions.doi') },
    { object: :universal, field_name: 'Handle', metadata_name: 'hdl', required: false, multivalued: :no, description: I18n.t('csv.descriptions.hdl') },
    { object: :file_set, field_name: 'Redirect to', metadata_name: 'redirect_to', required: false, multivalued: :no, description: I18n.t('csv.descriptions.redirect_to') }
  ].freeze

# Any fields related to "representative" relationships between FileSets and their parent Monograph
FILE_SET_FLAG_FIELDS ||=
  [
    { object: :file_set, field_name: 'Representative Kind', metadata_name: 'representative_kind', required: false, multivalued: :no, acceptable_values: FeaturedRepresentative::KINDS + ['cover'], description: I18n.t('csv.descriptions.representative_kind') }
  ].freeze

MONO_FILENAME_FLAG ||= '://:MONOGRAPH://:'
