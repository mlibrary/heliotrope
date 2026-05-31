module BlacklightOaiProvider
  module Response
    class ListSets < OAI::Provider::Response::Base
      def to_xml
        raise OAI::SetException unless provider.model.sets

        response do |r|
          r.ListSets do
            provider.model.sets.each do |set|
              r.set do
                r.setSpec set.spec
                r.setName set.name

                if set.respond_to?(:description) && set.description
                  r.setDescription do
                    r.tag!("#{oai_dc.prefix}:#{oai_dc.element_namespace}", oai_dc.header_specification) do
                      r.dc :description, set.description
                    end
                  end
                end
              end
            end
          end
        end
      end

      private

      def oai_dc
        OAI::Provider::Metadata::DublinCore.instance
      end
    end
  end
end
