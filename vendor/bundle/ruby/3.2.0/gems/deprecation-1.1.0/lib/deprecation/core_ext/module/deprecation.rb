class Module
  def deprecation_deprecate *method_names
    Deprecation.deprecate_methods(self, *method_names)
  end
end
