# frozen_string_literal: true
module YARD
  class EndpointHandler < Handlers::Ruby::MethodHandler
    handles method_call(:add_endpoint)
    namespace_only

    process do
      register(
        CodeObjects::MethodObject.new(namespace, name) do |m|
          m.parameters = parameters
        end,
        CodeObjects::MethodObject.new(P('DropboxApi::Client'), name) do |m|
          m.parameters = parameters
          m.group = namespace.namespace.name.downcase
        end
      )
    end

    def name
      statement.parameters.first.jump(:tstring_content, :ident).source
    end

    def parameters
      # This method is taken from YARD, ideally we would just use it but I
      # couldn't find a way to invoke it from here, so I had to copy it over.
      # It would be nice to get rid of this method and use YARD's
      # implementation instead.
      #
      # Reference to original code:
      #   YARD gem (0.9.5): lib/yard/handlers/ruby/method_handler.rb
      #   Github: https://git.io/vMLQp
      args = statement.jump(:block_var).jump(:params)
      return [] unless args.is_a? YARD::Parser::Ruby::ParameterNode

      params = []

      if args.unnamed_required_params
        params += args.unnamed_required_params.map {|a| [a.source, nil] }
      end

      if args.unnamed_optional_params
        params += args.unnamed_optional_params.map do |a|
          [a[0].source, a[1].source]
        end
      end

      params << ['*' + args.splat_param.source, nil] if args.splat_param

      if args.unnamed_end_params
        params += args.unnamed_end_params.map {|a| [a.source, nil] }
      end

      if args.named_params
        params += args.named_params.map do |a|
          [a[0].source, a[1] ? a[1].source : nil]
        end
      end

      if args.double_splat_param
        params << ['**' + args.double_splat_param.source, nil]
      end

      params << ['&' + args.block_param.source, nil] if args.block_param

      params
    end
  end
end
