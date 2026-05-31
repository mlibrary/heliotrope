# encoding: UTF-8
module RDF::Tabular
  ##
  # Utilities for parsing UAX35 dates and numbers.
  #
  # @see https://www.unicode.org/reports/tr35
  module UAX35

    ##
    # Parse the date pattern (if provided), and match against the value (if provided)
    # Otherwise, validate pattern and raise an error.
    #
    # Supported patterns are:
    #
    # * yyyy-MM-dd
    # * yyyyMMdd
    # * dd-MM-yyyy
    # * d-M-yyyy
    # * d-M-yy
    # * d-M-y
    # * MM-dd-yyyy
    # * M-d-yyyy
    # * M-d-yy
    # * M-d-y
    # * dd/MM/yyyy
    # * d/M/yyyy
    # * d/M/yy
    # * d/M/y
    # * MM/dd/yyyy
    # * M/d/yyyy
    # * M/d/yy
    # * M/d/y
    # * dd.MM.yyyy
    # * d.M.yyyy
    # * d.M.yy
    # * d.M.y
    # * MM.dd.yyyy
    # * M.d.yyyy
    # * M.d.yy
    # * M.d.y
    # * yyyy-MM-ddTHH:mm
    # * yyyy-MM-ddTHH:mm:ss
    # * yyyy-MM-ddTHH:mm:ss.S+
    #
    # Year comonents less than four digits are normalized to 1900 or 2000 based on if the value is <= 99 or >= 70, it is considered to be in the 1900 range, otherwise, based on 2000.
    #
    # @param [String] pattern
    # @param [String] value
    # @return [String] XMLSchema version of value
    # @raise [ArgumentError] if pattern is not valid, or nil
    # @raise [ParseError] if value does not match
    def parse_uax35_date(pattern, value)
      date_pattern, time_pattern = nil, nil
      return value unless pattern
      orig_value = value ||= ""
      orig_pattern = pattern

      # Extract tz info
      if md = pattern.match(/^(.*[dyms])+(\s*[xX]+)$/)
        pattern, tz_pattern = md[1], md[2]
      end

      date_pattern, time_pattern = pattern.split(' ')
      # Snuff out if this is a Time pattern
      date_pattern, time_pattern = nil, date_pattern if time_pattern.nil? && !date_pattern.match(/[TyMd]/)

      # Extract date, of specified
      date_part = case date_pattern
      when 'yyyy-MM-dd' then value.match(/^(?<yr>\d{4})-(?<mo>\d{2})-(?<da>\d{2})/)
      when 'yyyyMMdd'   then value.match(/^(?<yr>\d{4})(?<mo>\d{2})(?<da>\d{2})/)
      when 'dd-MM-yyyy' then value.match(/^(?<da>\d{2})-(?<mo>\d{2})-(?<yr>\d{4})/)
      when 'd-M-yyyy'   then value.match(/^(?<da>\d{1,2})-(?<mo>\d{1,2})-(?<yr>\d{4})/)
      when 'd-M-yy'     then value.match(/^(?<da>\d{1,2})-(?<mo>\d{1,2})-(?<yr>\d{2})/)
      when 'd-M-y'      then value.match(/^(?<da>\d{1,2})-(?<mo>\d{1,2})-(?<yr>\d{1,4})/)
      when 'MM-dd-yyyy' then value.match(/^(?<mo>\d{2})-(?<da>\d{2})-(?<yr>\d{4})/)
      when 'M-d-yyyy'   then value.match(/^(?<mo>\d{1,2})-(?<da>\d{1,2})-(?<yr>\d{4})/)
      when 'M-d-yy'     then value.match(/^(?<mo>\d{1,2})-(?<da>\d{1,2})-(?<yr>\d{2})/)
      when 'M-d-y'      then value.match(/^(?<mo>\d{1,2})-(?<da>\d{1,2})-(?<yr>\d{1,4})/)
      when 'dd/MM/yyyy' then value.match(/^(?<da>\d{2})\/(?<mo>\d{2})\/(?<yr>\d{1,4})/)
      when 'd/M/yyyy'   then value.match(/^(?<da>\d{1,2})\/(?<mo>\d{1,2})\/(?<yr>\d{4})/)
      when 'd/M/yy'     then value.match(/^(?<da>\d{1,2})\/(?<mo>\d{1,2})\/(?<yr>\d{2})/)
      when 'd/M/y'      then value.match(/^(?<da>\d{1,2})\/(?<mo>\d{1,2})\/(?<yr>\d{1,4})/)
      when 'MM/dd/yyyy' then value.match(/^(?<mo>\d{2})\/(?<da>\d{2})\/(?<yr>\d{1,4})/)
      when 'M/d/yyyy'   then value.match(/^(?<mo>\d{1,2})\/(?<da>\d{1,2})\/(?<yr>\d{4})/)
      when 'M/d/yy'     then value.match(/^(?<mo>\d{1,2})\/(?<da>\d{1,2})\/(?<yr>\d{2})/)
      when 'M/d/y'      then value.match(/^(?<mo>\d{1,2})\/(?<da>\d{1,2})\/(?<yr>\d{1,4})/)
      when 'dd.MM.yyyy' then value.match(/^(?<da>\d{2})\.(?<mo>\d{2})\.(?<yr>\d{4})/)
      when 'd.M.yyyy'   then value.match(/^(?<da>\d{1,2})\.(?<mo>\d{1,2})\.(?<yr>\d{4})/)
      when 'd.M.yy'     then value.match(/^(?<da>\d{1,2})\.(?<mo>\d{1,2})\.(?<yr>\d{2})/)
      when 'd.M.y'      then value.match(/^(?<da>\d{1,2})\.(?<mo>\d{1,2})\.(?<yr>\d{1,4})/)
      when 'MM.dd.yyyy' then value.match(/^(?<mo>\d{2})\.(?<da>\d{2})\.(?<yr>\d{4})/)
      when 'M.d.yyyy'   then value.match(/^(?<mo>\d{1,2})\.(?<da>\d{1,2})\.(?<yr>\d{4})/)
      when 'M.d.yy'     then value.match(/^(?<mo>\d{1,2})\.(?<da>\d{1,2})\.(?<yr>\d{2})/)
      when 'M.d.y'      then value.match(/^(?<mo>\d{1,2})\.(?<da>\d{1,2})\.(?<yr>\d{1,4})/)
      when 'yyyy-MM-ddTHH:mm' then value.match(/^(?<yr>\d{4})-(?<mo>\d{2})-(?<da>\d{2})T(?<hr>\d{2}):(?<mi>\d{2})(?<se>(?<ms>))/)
      when 'yyyy-MM-ddTHH:mm:ss' then value.match(/^(?<yr>\d{4})-(?<mo>\d{2})-(?<da>\d{2})T(?<hr>\d{2}):(?<mi>\d{2}):(?<se>\d{2})(?<ms>)/)
      when /yyyy-MM-ddTHH:mm:ss\.S+/
        md = value.match(/^(?<yr>\d{4})-(?<mo>\d{2})-(?<da>\d{2})T(?<hr>\d{2}):(?<mi>\d{2}):(?<se>\d{2})\.(?<ms>\d+)/)
        num_ms = date_pattern.match(/S+/).to_s.length
        md if md && md[:ms].length <= num_ms
      else
        raise ArgumentError, "unrecognized date/time pattern #{date_pattern}" if date_pattern
        nil
      end

      # Forward past date part
      if date_part
        value = value[date_part.to_s.length..-1]
        value = value.lstrip if date_part && value.start_with?(' ')
      end

      # Extract time, of specified
      time_part = case time_pattern
      when 'HH:mm:ss' then value.match(/^(?<hr>\d{2}):(?<mi>\d{2}):(?<se>\d{2})(?<ms>)/)
      when 'HHmmss'   then value.match(/^(?<hr>\d{2})(?<mi>\d{2})(?<se>\d{2})(?<ms>)/)
      when 'HH:mm'    then value.match(/^(?<hr>\d{2}):(?<mi>\d{2})(?<se>)(?<ms>)/)
      when 'HHmm'     then value.match(/^(?<hr>\d{2})(?<mi>\d{2})(?<se>)(?<ms>)/)
      when /HH:mm:ss\.S+/
        md = value.match(/^(?<hr>\d{2}):(?<mi>\d{2}):(?<se>\d{2})\.(?<ms>\d+)/)
        num_ms = time_pattern.match(/S+/).to_s.length
        md if md && md[:ms].length <= num_ms
      else
        raise ArgumentError, "unrecognized date/time pattern #{pattern}" if time_pattern
        nil
      end

      # If there's a date_pattern but no date_part, match fails
      raise ParseError, "#{orig_value} does not match pattern #{orig_pattern}" if !orig_value.empty? && date_pattern && date_part.nil?

      # If there's a time_pattern but no time_part, match fails
      raise ParseError, "#{orig_value} does not match pattern #{orig_pattern}" if !orig_value.empty? && time_pattern && time_part.nil?

      # Forward past time part
      value = value[time_part.to_s.length..-1] if time_part

      # Use datetime match for time
      time_part = date_part if date_part && date_part.names.include?("hr")

      # If there's a timezone, it may optionally start with whitespace
      value = value.lstrip if tz_pattern.to_s.start_with?(' ')
      tz_part = case tz_pattern.to_s.lstrip
      when 'x'    then value.match(/^(?:(?<hr>[+-]\d{2})(?<mi>\d{2})?)$/)
      when 'X'    then value.match(/^(?:(?:(?<hr>[+-]\d{2})(?<mi>\d{2})?)|(?<z>Z))$/)
      when 'xx'   then value.match(/^(?:(?<hr>[+-]\d{2})(?<mi>\d{2}))|$/)
      when 'XX'   then value.match(/^(?:(?:(?<hr>[+-]\d{2})(?<mi>\d{2}))|(?<z>Z))$/)
      when 'xxx'  then value.match(/^(?:(?<hr>[+-]\d{2}):(?<mi>\d{2}))$/)
      when 'XXX'  then value.match(/^(?:(?:(?<hr>[+-]\d{2}):(?<mi>\d{2}))|(?<z>Z))$/)
      else
        raise ArgumentError, "unrecognized timezone pattern #{tz_pattern.to_s.lstrip}" if tz_pattern
        nil
      end

      # If there's a tz_pattern but no time_part, match fails
      raise ParseError, "#{orig_value} does not match pattern #{orig_pattern}" if !orig_value.empty? && tz_pattern && tz_part.nil?

      # Compose normalized value
      vd = if date_part
        yr, mo, da = [date_part[:yr], date_part[:mo], date_part[:da]].map(&:to_i)

        if date_part[:yr].length < 4
          # Make sure that yr makes sense, if given
          yr = case yr
          when 0..69    then yr + 2000
          when 100..999 then yr + 2000
          when 70..99   then yr + 1900
          else               yr
          end
        end

        ("%04d-%02d-%02d" % [yr, mo, da])
      end

      vt = ("%02d:%02d:%02d" % [time_part[:hr].to_i, time_part[:mi].to_i, time_part[:se].to_i]) if time_part

      # Add milliseconds, if matched
      vt += ".#{time_part[:ms]}" if time_part && !time_part[:ms].empty?

      value = [vd, vt].compact.join('T')
      value += tz_part[:z] ? "Z" : ("%s:%02d" % [tz_part[:hr], tz_part[:mi].to_i]) if tz_part
      value
    end

    ##
    # Parse the date pattern (if provided), and match against the value (if provided)
    # Otherwise, validate pattern and raise an error
    #
    # @param [String] pattern
    # @param [String] value
    # @param [String] groupChar
    # @param [String] decimalChar
    # @return [String] XMLSchema version of value or nil, if value does not match
    # @raise [ArgumentError] if pattern is not valid
    def parse_uax35_number(pattern, value, groupChar=",", decimalChar=".")
      value ||= ""

      re = build_number_re(pattern, groupChar, decimalChar)

      raise ParseError, "#{value} has repeating #{groupChar.inspect}" if groupChar.length == 1 && value.include?(groupChar*2)

      # Upcase value and remove internal spaces
      value = value.upcase

      if value =~ re
        # Upcase value and remove internal spaces
        value = value.
          gsub(/\s+/, '').
          gsub(groupChar, '').
          gsub(decimalChar, '.')

        # result re-assembles parts removed from value
        value
      elsif !value.empty?
        # no match
        raise ParseError, "#{value.inspect} does not match #{pattern.inspect}"
      end

      # Extract percent or per-mille sign
      case value
      when /%/
        value = value.sub('%', '')
        lhs, rhs = value.split('.')

        # Shift decimal
        value = case lhs.length
        when 0 then "0.00#{rhs}".sub('E', 'e')
        when 1 then "0.0#{lhs}#{rhs}".sub('E', 'e')
        when 2 then "0.#{lhs}#{rhs}".sub('E', 'e')
        else
          ll, lr = lhs[0..lhs.length-3], lhs[-2..-1]
          ll = ll + "0" unless ll =~ /\d+/
          "#{ll}.#{lr}#{rhs}".sub('E', 'e')
        end
      when /‰/
        value = value.sub('‰', '')
        lhs, rhs = value.split('.')

        # Shift decimal
        value = case lhs.length
        when 0 then "0.000#{rhs}".sub('E', 'e')
        when 1 then "0.00#{lhs}#{rhs}".sub('E', 'e')
        when 2 then "0.0#{lhs}#{rhs}".sub('E', 'e')
        when 3 then "0.#{lhs}#{rhs}".sub('E', 'e')
        else
          ll, lr = lhs[0..lhs.length-4], lhs[-3..-1]
          ll = ll + "0" unless ll =~ /\d+/
          "#{ll}.#{lr}#{rhs}".sub('E', 'e')
        end
      when /NAN/ then value.sub('NAN', 'NaN')
      when /E/ then value.sub('E', 'e')
      else
        value
      end
    end

    # Build a regular expression from the provided pattern to match value, after suitable modifications
    #
    # @param [String] pattern
    # @param [String] groupChar
    # @param [String] decimalChar
    # @return [Regexp] Regular expression matching value
    # @raise [ArgumentError] if pattern is not valid
    def build_number_re(pattern, groupChar, decimalChar)
      # pattern must be composed of only 0, #, decimalChar, groupChar, E, %, and ‰

      ge = Regexp.escape groupChar
      de = Regexp.escape decimalChar

      default_pattern = /^
        ([+-]?
         [\d#{ge}]+
         (#{de}[\d#{ge}]+
          ([Ee][+-]?\d+)?
         )?[%‰]?
        |NAN|INF|-INF)
      $/x

      return default_pattern if pattern.nil?
      numeric_pattern = /
        # Mantissa
        (\#|#{ge})*
        (0|#{ge})*
        # Fractional
        (?:#{de}
          (0|#{ge})*
          (\#|#{ge})*
          # Exponent
          (E
            [+-]?
            (?:\#|#{ge})*
            (?:0|#{ge})*
          )?
        )?
      /x

      legal_number_pattern = /^(?<prefix>[^\#0]*)(?<numeric_part>#{numeric_pattern})(?<suffix>.*)$/x

      match = legal_number_pattern.match(pattern)
      raise ArgumentError, "unrecognized number pattern #{pattern}" if match["numeric_part"].empty?

      prefix, numeric_part, suffix = match["prefix"], match["numeric_part"], match["suffix"]
      prefix = Regexp.escape prefix unless prefix.empty?
      prefix += "[+-]?" unless prefix =~ /[+-]/
      suffix = Regexp.escape suffix unless suffix.empty?

      # Split on decimalChar and E
      parts = numeric_part.split("E")
      mantissa_part, exponent_part = parts[0], (parts[1] || '')

      mantissa_parts = mantissa_part.split(decimalChar)
      raise ArgumentError, "Multiple decimal separators in #{pattern}" if mantissa_parts.length > 2
      integer_part, fractional_part = mantissa_parts[0], mantissa_parts[1] || ''

      min_integer_digits = integer_part.gsub(groupChar, '').gsub('#', '').length
      all_integer_digits = integer_part.gsub(groupChar, '').length
      all_integer_digits += 1 if all_integer_digits == min_integer_digits
      min_fractional_digits = fractional_part.gsub(groupChar, '').gsub('#', '').length
      max_fractional_digits = fractional_part.gsub(groupChar, '').length
      exponent_sign = exponent_part[0] if exponent_part =~ /^[+-]/
      min_exponent_digits = exponent_part.sub(/[+-]/, '').gsub("#", "").length
      max_exponent_digits = exponent_part.sub(/[+-]/, '').length

      integer_parts = integer_part.split(groupChar)[1..-1]
      primary_grouping_size = integer_parts[-1].to_s.length
      secondary_grouping_size = integer_parts.length <= 1 ? primary_grouping_size : integer_parts[-2].length

      fractional_parts = fractional_part.split(groupChar)[0..-2]
      fractional_grouping_size = fractional_parts[0].to_s.length

      # Construct regular expression for integer part
      integer_str = if primary_grouping_size == 0
        "\\d{#{min_integer_digits},}"
      else
        # These number of groupings must be there
        integer_parts = []
        integer_rem = 0
        while min_integer_digits > 0
          sz = [primary_grouping_size, min_integer_digits].min
          integer_rem = primary_grouping_size - sz
          integer_parts << "\\d{#{sz}}"
          min_integer_digits -= sz
          all_integer_digits -= sz
          primary_grouping_size = secondary_grouping_size
        end
        required_digits = integer_parts.reverse.join(ge)

        if all_integer_digits > 0
          # Add digits up to end of group creating
          # (?:(?:\d)?)\d)? ...
          integer_parts = []
          while integer_rem > 0
            integer_parts << '\d'
            integer_rem -= 1
          end

          # If secondary_grouping_size is not primary_grouping_size, add digits up to secondary_grouping_size
          if secondary_grouping_size != primary_grouping_size
            primary_grouping_size = secondary_grouping_size
            integer_rem = primary_grouping_size - 1
            integer_parts << '\d' + ge

            while integer_rem > 0
              integer_parts << '\d'
              integer_rem -= 1
            end
          end

          # Allow repeated separated groups
          if integer_parts.empty?
            opt_digits = "(?:\\d{1,#{primary_grouping_size}}#{ge})?(?:\\d{#{primary_grouping_size}}#{ge})*"
          else
            integer_parts[-1] = "(?:\\d{1,#{primary_grouping_size}}#{ge})?(?:\\d{#{primary_grouping_size}}#{ge})*#{integer_parts[-1]}"
            opt_digits = integer_parts.reverse.inject("") {|memo, part| "(?:#{memo}#{part})?"}
          end

          opt_digits + required_digits
        else
          required_digits
        end
      end

      # Construct regular expression for fractional part
      fractional_str = if max_fractional_digits > 0
        if fractional_grouping_size == 0
          min_fractional_digits == max_fractional_digits ? "\\d{#{max_fractional_digits}}" : "\\d{#{min_fractional_digits},#{max_fractional_digits}}"
        else
          # These number of groupings must be there
          fractional_parts = []
          fractional_rem = 0
          while min_fractional_digits > 0
            sz = [fractional_grouping_size, min_fractional_digits].min
            fractional_rem = fractional_grouping_size - sz
            fractional_parts << "\\d{#{sz}}"
            max_fractional_digits -= sz
            min_fractional_digits -= sz
          end
          required_digits = fractional_parts.join(ge)

          # If max digits fill within existing group
          fractional_parts = []
          while max_fractional_digits > 0
            fractional_parts << (fractional_rem == 0 ? ge + '\d' : '\d')
            max_fractional_digits -= 1
            fractional_rem = (fractional_rem - 1) % fractional_grouping_size
          end

          opt_digits = fractional_parts.reverse.inject("") {|memo, part| "(?:#{part}#{memo})?"}
          required_digits + opt_digits
        end
      end.to_s
      fractional_str = de + fractional_str unless fractional_str.empty?
      fractional_str = "(?:#{fractional_str})?" if max_fractional_digits > 0 && min_fractional_digits == 0

      # Exponent pattern
      exponent_str = case
      when max_exponent_digits > 0 && max_exponent_digits == min_exponent_digits
        "E#{exponent_sign ? Regexp.escape(exponent_sign) : '[+-]?'}\\d{#{max_exponent_digits}}"
      when max_exponent_digits > 0
        "E#{exponent_sign ? Regexp.escape(exponent_sign) : '[+-]?'}\\d{#{min_exponent_digits},#{max_exponent_digits}}"
      when min_exponent_digits > 0
        "E#{exponent_sign ? Regexp.escape(exponent_sign) : '[+-]?'}\\d{#{min_exponent_digits},#{max_exponent_digits}}"
      end

      Regexp.new("^(?<prefix>#{prefix})(?<numeric_part>#{integer_str}#{fractional_str}#{exponent_str})(?<suffix>#{suffix})$")
    end

    # ParseError is raised when a value does not match the pattern
    class ParseError < RuntimeError; end
  end
end
