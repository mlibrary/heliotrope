class PressSearchBuilder < ::SearchBuilder
  self.default_processor_chain += [:filter_by_press]

  def filter_by_press(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!term f=press_sim}#{blacklight_params['subdomain']}"
  end
end
