# frozen_string_literal: true

# something to note is that the multivalued :yes/:no values mirror the model, such that assignment will work properly as a scalar or array...
# :yes_split means that this is a field we actually want to *use* as multivalued, and so will split the CSV field on semicolons to do so
# :yes_multiline means we only want to use <fieldname>.first of a multi-valued field to store all our values, which will be separated with a new line within that string

METADATA_FIELDS ||=
  [
    { object: :universal, field_name: 'Title', metadata_name: 'title', required: true, multivalued: :yes },
    { object: :file_set, field_name: 'Resource Type', metadata_name: 'resource_type', required: true, multivalued: :yes, acceptable_values: ['audio', 'image', 'dataset', 'table', '3D model', 'text', 'video'] },
    { object: :file_set, field_name: 'External Resource URL', metadata_name: 'external_resource_url', required: false, multivalued: :no },
    { object: :file_set, field_name: 'Caption', metadata_name: 'caption', required: true, multivalued: :yes },
    { object: :file_set, field_name: 'Alternative Text', metadata_name: 'alt_text', required: true, multivalued: :yes },
    { object: :universal, field_name: 'Copyright Holder', metadata_name: 'copyright_holder', required: true, multivalued: :no },
    { object: :file_set, field_name: 'Allow High-Res Display?', metadata_name: 'allow_hi_res', required: true, multivalued: :no, acceptable_values: ['yes', 'no', 'not hosted on the platform'] },
    { object: :file_set, field_name: 'Allow Download?', metadata_name: 'allow_download', required: true, multivalued: :no, acceptable_values: ['yes', 'no', 'not hosted on the platform'] },
    { object: :file_set, field_name: 'Copyright Status', metadata_name: 'copyright_status', required: true, multivalued: :no, acceptable_values: ['in-copyright', 'public domain', 'status unknown'] },
    { object: :file_set, field_name: 'Rights Granted', metadata_name: 'rights_granted', required: false, multivalued: :no },
    # there is also a `Hyrax::LicenseService.new.select_all_options` method if we want to not warn when importing old CC licenses
    { object: :universal, field_name: 'CC License', metadata_name: 'license', required: false, multivalued: :yes, acceptable_values: Hyrax::LicenseService.new.select_active_options.map { |a| a[1] } },
    { object: :file_set, field_name: 'Permissions Expiration Date', metadata_name: 'permissions_expiration_date', required: false, multivalued: :no, date_format: true },
    { object: :file_set, field_name: 'After Expiration: Allow Display?', metadata_name: 'allow_display_after_expiration', required: false, multivalued: :no, acceptable_values: ['none', 'high-res', 'low-res', 'not hosted on the platform'] },
    { object: :file_set, field_name: 'After Expiration: Allow Download?', metadata_name: 'allow_download_after_expiration', required: false, multivalued: :no, acceptable_values: ['yes', 'no', 'not hosted on the platform'] },
    { object: :file_set, field_name: 'Credit Line', metadata_name: 'credit_line', required: false, multivalued: :no },
    { object: :universal, field_name: 'Holding Contact', metadata_name: 'holding_contact', required: false, multivalued: :no },
    { object: :file_set, field_name: 'Exclusive to Fulcrum', metadata_name: 'exclusive_to_platform', required: false, multivalued: :no, acceptable_values: ['yes', 'no'] },
    { object: :universal, field_name: 'DOI', metadata_name: 'doi', required: false, multivalued: :no },
    { object: :universal, field_name: 'Handle', metadata_name: 'hdl', required: false, multivalued: :no },
    { object: :file_set, field_name: 'Content Type', metadata_name: 'content_type', required: false, multivalued: :yes_split },
    { object: :universal, field_name: 'Creator(s)', metadata_name: 'creator', required: false, multivalued: :yes_multiline },
    { object: :universal, field_name: 'Additional Creator(s)', metadata_name: 'contributor', required: false, multivalued: :yes_multiline },
    { object: :file_set, field_name: 'Sort Date', metadata_name: 'sort_date', required: false, multivalued: :no, date_format: true },
    { object: :file_set, field_name: 'Display Date', metadata_name: 'display_date', required: false, multivalued: :yes_split },
    { object: :universal, field_name: 'Description', metadata_name: 'description', required: false, multivalued: :yes },
    { object: :file_set, field_name: 'Keywords', metadata_name: 'keywords', required: false, multivalued: :yes_split },
    { object: :file_set, field_name: 'Section', metadata_name: 'section_title', required: false, multivalued: :yes },
    { object: :file_set, field_name: 'Language', metadata_name: 'language', required: false, multivalued: :yes_split },
    { object: :file_set, field_name: 'Transcript', metadata_name: 'transcript', required: false, multivalued: :no },
    { object: :file_set, field_name: 'Translation', metadata_name: 'translation', required: false, multivalued: :yes },
    { object: :file_set, field_name: 'Redirect to', metadata_name: 'redirect_to', required: false, multivalued: :no },
    { object: :monograph, field_name: 'Publisher', metadata_name: 'publisher', multivalued: :yes },
    { object: :monograph, field_name: 'Subject', metadata_name: 'subject', multivalued: :yes_split },
    { object: :monograph, field_name: 'ISBN(s)', metadata_name: 'isbn', multivalued: :yes_split },
    { object: :monograph, field_name: 'Buy Book URL', metadata_name: 'buy_url', multivalued: :yes },
    { object: :monograph, field_name: 'Pub Year', metadata_name: 'date_created', multivalued: :yes },
    { object: :monograph, field_name: 'Pub Location', metadata_name: 'location', multivalued: :no },
    { object: :universal, field_name: 'Identifier(s)', metadata_name: 'identifier', required: false, multivalued: :yes_split },
    { object: :monograph, field_name: 'Series', metadata_name: 'series', multivalued: :yes_split }
  ].freeze

MONO_FILENAME_FLAG ||= '://:MONOGRAPH://:'
