# frozen_string_literal: true
module YARD
  module Templates::Helpers
    module HtmlHelper
      def unindent(str)
        indent_size = str.split("\n").map do |line|
          line = untab(line)
          white_span = line[/\A(\s+)/]

          white_span.nil? ? nil : white_span.size
        end.compact.min

        str.gsub(/^( ){#{indent_size}}/, '')
      end

      def untab(str, tab_size = 2)
        tab_space = 2

        str.gsub("\t", ' ' * tab_space)
      end
    end
  end
end
