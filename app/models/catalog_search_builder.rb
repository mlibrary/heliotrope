# frozen_string_literal: true

# Search builder for the full-catalog endpoints (CatalogController and its
# subclass AdminCatalogController).
#
# The default Hyrax::FilterByType behavior (mixed in via Hyrax::SearchFilters ->
# ::SearchBuilder) limits results to work + collection models, which excludes
# FileSets. For the full catalog we want the default, unfiltered results to
# contain Monographs (from all presses) *and* FileSets, so we override #models
# to add FileSet and drop collections.
class CatalogSearchBuilder < ::SearchBuilder
  # Include FileSets alongside the registered work types (Monograph), and omit
  # collection classes.
  def models
    work_classes + [::FileSet]
  end
end
