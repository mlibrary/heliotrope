# Extend builder to allow for better control of whitespace in XML Literals

require 'builder'

module Builder
  # Extends XmlMarkup#tag! to better control whitespace when adding content from a block
  #
  class RdfXml < Builder::XmlMarkup
    # Create a tag named +sym+.  Other than the first argument which
    # is the tag name, the arguments are the same as the tags
    # implemented via <tt>method_missing</tt>.
    #
    # @see https://github.com/jimweirich/builder/blob/master/lib/builder/xmlbase.rb
    def tag!(sym, *args, &block)
      text = nil
      attrs = args.last.is_a?(::Hash) ? args.last : {}
      return super unless block && attrs[:no_whitespace]
      attrs.delete(:no_whitespace)

      sym = "#{sym}:#{args.shift}".to_sym if args.first.kind_of?(::Symbol)

      args.each do |arg|
        case arg
        when ::Hash
          attrs.merge!(arg)
        when nil
          attrs.merge!({:nil => true}) if explicit_nil_handling?
        else
          text ||= ''
          text << arg.to_s
        end
      end

      unless text.nil?
        ::Kernel::raise ::ArgumentError,
          "XmlMarkup cannot mix a text argument with a block"
      end

      # Indent
      _indent
      #unless @indent == 0 || @level == 0
      #  text!(" " * (@level * @indent))
      #end

      _start_tag(sym, attrs)
      begin
        _nested_structures(block)
      ensure
        _end_tag(sym)
        _newline
      end
    end
  end
end
