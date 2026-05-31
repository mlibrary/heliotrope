require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/array/extract_options'

module Deprecation
  # Declare that a method has been deprecated.
  def self.deprecate_methods(target_module, *method_names)
    options = method_names.extract_options!
    method_names += options.keys

    generated_deprecation_methods = Module.new
    method_names.each do |method_name|
      if RUBY_VERSION < '3'
        generated_deprecation_methods.module_eval(<<-end_eval, __FILE__, __LINE__ + 1)
          def #{method_name}(*args, &block)
            Deprecation.warn(#{target_module.to_s},
              Deprecation.deprecated_method_warning(#{target_module.to_s},
                :#{method_name},
                #{options[method_name].inspect}),
              caller
            )
            super
          end
          pass_keywords(:#{method_name}) if respond_to?(:pass_keywords, true)
        end_eval
      else
        generated_deprecation_methods.module_eval(<<-end_eval, __FILE__, __LINE__ + 1)
          def #{method_name}(*args, **kwargs, &block)
            Deprecation.warn(#{target_module.to_s},
              Deprecation.deprecated_method_warning(#{target_module.to_s},
                :#{method_name},
                #{options[method_name].inspect}),
              caller
            )
            super
          end
        end_eval
      end
    end
    target_module.prepend generated_deprecation_methods
  end
end
