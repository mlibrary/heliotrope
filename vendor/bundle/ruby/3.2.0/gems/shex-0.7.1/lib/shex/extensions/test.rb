##
# Test extension.
#
# Default implementation of http://shex.io/extensions/Test/
#
# @see http://shex.io/extensions/Test/
require 'shex'

module ShEx
  Test = Class.new(ShEx::Extension("http://shex.io/extensions/Test/")) do
    # (see ShEx::Extension#visit)
    def visit(code: nil, matched: nil, depth: 0, **options)
      str = if md = /^ *(fail|print) *\( *(?:(\"(?:[^\\"]|\\")*\")|([spo])) *\) *$/.match(code.to_s)
        md[2] || case md[3]
        when 's' then matched.subject
        when 'p' then matched.predicate
        when 'o' then matched.object
        else          matched.to_sxp
        end.to_s
      else
        matched ? matched.to_sxp : 'no statement'
      end

      $stdout.puts str
      return !md || md[1] == 'print'
    end
  end
end
