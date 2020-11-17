# frozen_string_literal: true

# https://tools.lib.umich.edu/jira/browse/HELIO-3595
# delete this override once our Hyrax version (stack) has the fix for this https://github.com/samvera/hyrax/issues/4581
ActiveFedora::Aggregation::ListSource.class_eval do
  prepend(HeliotropeActiveFedoraListSourceOverrides = Module.new do
    def attribute_will_change!(attr)
      return super unless attr == 'nodes'
      attributes_changed_by_setter[:nodes] = true
    end
  end)
end
