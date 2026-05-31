# encoding: UTF-8
$:.unshift "."
require 'spec_helper'

describe RDF::Tabular::UAX35 do
  subject {"".extend(RDF::Tabular::UAX35)}

  describe "parse_uax35_date" do
    {
      # Dates
      "valid date yyyy-MM-dd" => {value: "2015-03-22", pattern: "yyyy-MM-dd", result: "2015-03-22"},
      "valid date yyyyMMdd"   => {value: "20150322", pattern: "yyyyMMdd", result: "2015-03-22"},
      "valid date dd-MM-yyyy" => {value: "22-03-2015", pattern: "dd-MM-yyyy", result: "2015-03-22"},
      "valid date d-M-yyyy"   => {value: "22-3-2015", pattern: "d-M-yyyy", result: "2015-03-22"},
      "valid date d-M-yy"     => {value: "22-3-15", pattern: "d-M-yy", result: "2015-03-22"},
      "valid date d-M-y"      => {value: "22-3-15", pattern: "d-M-y", result: "2015-03-22"},
      "valid date MM-dd-yyyy" => {value: "03-22-2015", pattern: "MM-dd-yyyy", result: "2015-03-22"},
      "valid date M-d-yyyy"   => {value: "3-22-2015", pattern: "M-d-yyyy", result: "2015-03-22"},
      "valid date M-d-yy"     => {value: "3-22-70", pattern: "M-d-yy", result: "1970-03-22"},
      "valid date M-d-y"      => {value: "3-22-70", pattern: "M-d-y", result: "1970-03-22"},
      "valid date dd/MM/yyyy" => {value: "22/03/2015", pattern: "dd/MM/yyyy", result: "2015-03-22"},
      "valid date d/M/yyyy"   => {value: "22/3/2015", pattern: "d/M/yyyy", result: "2015-03-22"},
      "valid date d/M/yy"     => {value: "22/3/15", pattern: "d/M/yy", result: "2015-03-22"},
      "valid date d/M/y"      => {value: "22/3/15", pattern: "d/M/y", result: "2015-03-22"},
      "valid date MM/dd/yyyy" => {value: "03/22/2015", pattern: "MM/dd/yyyy", result: "2015-03-22"},
      "valid date M/d/yyyy"   => {value: "3/22/2015", pattern: "M/d/yyyy", result: "2015-03-22"},
      "valid date M/d/yy"     => {value: "3/22/15", pattern: "M/d/yy", result: "2015-03-22"},
      "valid date M/d/y"      => {value: "3/22/15", pattern: "M/d/y", result: "2015-03-22"},
      "valid date dd.MM.yyyy" => {value: "22.03.2015", pattern: "dd.MM.yyyy", result: "2015-03-22"},
      "valid date d.M.yyyy"   => {value: "22.3.2015", pattern: "d.M.yyyy", result: "2015-03-22"},
      "valid date d.M.yy"     => {value: "22.3.15", pattern: "d.M.yy", result: "2015-03-22"},
      "valid date d.M.y"      => {value: "22.3.15", pattern: "d.M.y", result: "2015-03-22"},
      "valid date MM.dd.yyyy" => {value: "03.22.2015", pattern: "MM.dd.yyyy", result: "2015-03-22"},
      "valid date M.d.yyyy"   => {value: "3.22.2015", pattern: "M.d.yyyy", result: "2015-03-22"},
      "valid date M.d.yy"     => {value: "3.22.15", pattern: "M.d.yy", result: "2015-03-22"},
      "valid date M.d.y"      => {value: "3.22.15", pattern: "M.d.y", result: "2015-03-22"},

      # Times
      "valid time HH:mm:ss.S" => {value: "15:02:37.1", pattern: "HH:mm:ss.S", result: "15:02:37.1"},
      "valid time HH:mm:ss"   => {value: "15:02:37", pattern: "HH:mm:ss", result: "15:02:37"},
      "valid time HHmmss"     => {value: "150237", pattern: "HHmmss", result: "15:02:37"},
      "valid time HH:mm"      => {value: "15:02", pattern: "HH:mm", result: "15:02:00"},
      "valid time HHmm"       => {value: "1502", pattern: "HHmm", result: "15:02:00"},

      # DateTimes
      "valid dateTime yyyy-MM-ddTHH:mm:ss"  => {value: "2015-03-15T15:02:37", pattern: "yyyy-MM-ddTHH:mm:ss", result: "2015-03-15T15:02:37"},
      "valid dateTime yyyy-MM-ddTHH:mm:ss.S"=> {value: "2015-03-15T15:02:37.1", pattern: "yyyy-MM-ddTHH:mm:ss.S", result: "2015-03-15T15:02:37.1"},
      "valid dateTime yyyy-MM-dd HH:mm:ss"  => {value: "2015-03-15 15:02:37", pattern: "yyyy-MM-dd HH:mm:ss", result: "2015-03-15T15:02:37"},
      "valid dateTime yyyyMMdd HHmmss"      => {value: "20150315 150237",   pattern: "yyyyMMdd HHmmss",   result: "2015-03-15T15:02:37"},
      "valid dateTime dd-MM-yyyy HH:mm"     => {value: "15-03-2015 15:02", pattern: "dd-MM-yyyy HH:mm", result: "2015-03-15T15:02:00"},
      "valid dateTime d-M-yyyy HHmm"        => {value: "15-3-2015 1502",  pattern: "d-M-yyyy HHmm",   result: "2015-03-15T15:02:00"},
      "valid dateTime yyyy-MM-ddTHH:mm"     => {value: "2015-03-15T15:02",  pattern: "yyyy-MM-ddTHH:mm",   result: "2015-03-15T15:02:00"},
      "valid dateTimeStamp d-M-yyyy HHmm X" => {value: "15-3-2015 1502 Z",  pattern: "d-M-yyyy HHmm X",   result: "2015-03-15T15:02:00Z"},
      "valid datetime yyyy-MM-ddTHH:mm:ss"  => {value: "2015-03-15T15:02:37", pattern: "yyyy-MM-ddTHH:mm:ss", result: "2015-03-15T15:02:37"},
      "valid datetime yyyy-MM-dd HH:mm:ss"  => {value: "2015-03-15 15:02:37", pattern: "yyyy-MM-dd HH:mm:ss", result: "2015-03-15T15:02:37"},
      "valid datetime yyyyMMdd HHmmss"      => {value: "20150315 150237",   pattern: "yyyyMMdd HHmmss",   result: "2015-03-15T15:02:37"},
      "valid datetime dd-MM-yyyy HH:mm"     => {value: "15-03-2015 15:02", pattern: "dd-MM-yyyy HH:mm", result: "2015-03-15T15:02:00"},
      "valid datetime d-M-yyyy HHmm"        => {value: "15-3-2015 1502",  pattern: "d-M-yyyy HHmm",   result: "2015-03-15T15:02:00"},
      "valid datetime yyyy-MM-ddTHH:mm"     => {value: "2015-03-15T15:02",  pattern: "yyyy-MM-ddTHH:mm",   result: "2015-03-15T15:02:00"},

      # Timezones
      "valid w/TZ yyyy-MM-ddX"              => {value: "2015-03-22Z", pattern: "yyyy-MM-ddX", result: "2015-03-22Z"},
      "valid w/TZ HH:mm:ssX"                => {value: "15:02:37-05", pattern: "HH:mm:ssX", result: "15:02:37-05:00"},
      "valid w/TZ yyyy-MM-dd HH:mm:ss X"    => {value: "2015-03-15 15:02:37 +0800", pattern: "yyyy-MM-dd HH:mm:ss X", result: "2015-03-15T15:02:37+08:00"},
      "valid w/TZ HHmm XX"                  => {value: "1502 +0800", pattern: "HHmm XX", result: "15:02:00+08:00"},
      "valid w/TZ yyyy-MM-dd HH:mm:ss XX"   => {value: "2015-03-15 15:02:37 -0800", pattern: "yyyy-MM-dd HH:mm:ss XX", result: "2015-03-15T15:02:37-08:00"},
      "valid w/TZ HHmm XXX"                 => {value: "1502 +08:00", pattern: "HHmm XXX", result: "15:02:00+08:00"},
      "valid w/TZ yyyy-MM-ddTHH:mm:ssXXX"   => {value: "2015-03-15T15:02:37-05:00", pattern: "yyyy-MM-ddTHH:mm:ssXXX", result: "2015-03-15T15:02:37-05:00"},
      "invalid w/TZ HH:mm:ssX"              => {value: "15:02:37-05:00", pattern: "HH:mm:ssX", error: "15:02:37-05:00 does not match pattern HH:mm:ssX"},
      "invalid w/TZ HH:mm:ssXX"             => {value: "15:02:37-05", pattern: "HH:mm:ssXX", error: "15:02:37-05 does not match pattern HH:mm:ssXX"},
    }.each do |name, props|
      context name do
        let(:base) {props[:base]}
        let(:pattern) {props[:pattern]}
        let(:value) {props[:value]}
        let(:result) {props.fetch(:result, value)}
        if props[:error]
          it "finds error" do
            expect {subject.parse_uax35_date(pattern, value)}.to raise_error(RDF::Tabular::UAX35::ParseError, props[:error])
          end
        else
          it "generates #{props[:result] || props[:value]}" do
            expect(subject.parse_uax35_date(pattern, value)).to eql result
          end
        end
      end
    end
  end

  describe "parse_uax35_number" do
    {
      # Numbers
      "default no constraints" => {valid: %w(4)},
      "default matching pattern" => {pattern: "000", valid: %w(123)},
      "default explicit groupChar" => {groupChar: ";", valid: {"123;456.789" => "123456.789"}},
      "default repeated groupChar" => {groupChar: ";", invalid: %w(123;;456.789)},
      "default explicit decimalChar" => {decimalChar: ";", valid: {"123456;789" => "123456.789"}},
      "default percent" => {groupChar: ",", valid: {"123456.789%" => "1234.56789"}},
      "default per-mille" => {groupChar: ",", valid: {"123456.789‰" => "123.456789"}},

      "0"          => {pattern: "0", valid: %w(1 -1 12), invalid: %w(1.2)},
      "00"         => {pattern: "00", valid: %w(12 123), invalid: %w(1 1,2)},
      "#"          => {pattern: "#", valid: %w(1 12 123), invalid: %w(1.2)},
      "##"         => {pattern: "##", valid: %w(1 12 123), invalid: %w(1.2)},
      "#0"         => {pattern: "#0", valid: %w(1 12 123), invalid: %w(1.2)},
      '0.0'        => {pattern: "0.0", valid: %w(1.1 -1.1 12.1), invalid: %w(1.12)},
      '0.00'       => {pattern: '0.00', valid: %w(1.12 +1.12 12.12), invalid: %w(1.1 1.123)},
      '0.#'        => {pattern: '0.#', valid: %w(1 1.1 12.1), invalid: %w(1.12)},
      '-0'         => {pattern: '-0', valid: %w(-1 -10), invalid: %w(1 +1)},
      '%000'       => {pattern: '%000', valid: {"%123" => "1.23", "%+123" => "+1.23", "%1234" => "12.34"}, invalid: %w(%12 123%)},
      '‰000'       => {pattern: '‰000', valid: {"‰123" => "0.123", "‰+123" => "+0.123", "‰1234" => "1.234"}, invalid: %w(‰12 123‰)},
      '000%'       => {pattern: '000%', valid: {"123%" => "1.23", "+123%" => "+1.23", "1234%" => "12.34"}, invalid: %w(12% %123)},
      '000‰'       => {pattern: '000‰', valid: {"123‰" => "0.123", "+123‰" => "+0.123", "1234‰" => "1.234"}, invalid: %w(12‰ ‰123)},
      '000.0%'     => {pattern: '000.0%', valid: {"123.4%" => "1.234", "+123.4%" => "+1.234"}, invalid: %w(123.4‰ 123.4 1.234% 12.34% 123.45%)},
      
      '###0.#####' => {pattern: '###0.#####', valid: %w(1 1.1 12345.12345), invalid: %w(1,234.1 1.123456)},
      '###0.0000#' => {pattern: '###0.0000#', valid: %w(1.1234 1.12345 12345.12345), invalid: %w(1,234.1234 1.12)},
      '00000.0000' => {pattern: '00000.0000', valid: %w(12345.1234), invalid: %w(1.2 1,234.123,4)},
      
      '#0.0#E#0'   => {pattern: '#0.0#E#0', valid: %w(1.2e3 12.34e56)},
      '#0.0#E+#0'  => {pattern: '#0.0#E+#0', valid: %w(1.2e+3 12.34e+56), invalid: %w(1.2e3 12.34e56)},
      '#0.0#E#0%'  => {pattern: '#0.0#E#0%', valid: {"1.2e3%" => "0.012e3", "12.34e56%" => "0.1234e56"}, invalid: %w(1.2e+3 12.34e+56 1.2e3 12.34e56)},
      
      # Grouping
      '#,##,##0'   => {pattern: '#,##,##0', valid: {"1" => "1", "12" => "12", "123" => "123", "1,234" => "1234", "12,345" => "12345", "1,23,456" => "123456"}, invalid: %w(1,2 12,34)},
      '#,##,#00'   => {pattern: '#,##,#00', valid: {"12" => "12", "123" => "123", "1,234" => "1234", "12,345" => "12345"}, invalid: %w(1)},
      '#,##,000'   => {pattern: '#,##,000', valid: {"123" => "123", "1,234" => "1234", "12,345" => "12345"}, invalid: %w(1 12)},
      '#,#0,000'   => {pattern: '#,#0,000', valid: {"1,234" => "1234", "12,345" => "12345"}, invalid: %w(1 12 123)},
      '#,00,000'   => {pattern: '#,00,000', valid: {"12,345" => "12345"}, invalid: %w(1 12 123 1,234)},
      '0,00,000'   => {pattern: '0,00,000'},
      
      '0.0##,###'  => {pattern: '0.0##,###'},
      '0.00#,###'  => {pattern: '0.00#,###'},
      '0.000,###'  => {pattern: '0.000,###'},
      '0.000,0##'  => {pattern: '0.000,0##'},
      '0.000,00#'  => {pattern: '0.000,00#'},
      '0.000,000'  => {pattern: '0.000,000'},
      
      # Jeni's
      '##0'        => {pattern: '##0', valid: %w(1 12 123 1234), invalid: %w(1,234 123.4)},
      '#,#00'      => {pattern: '#,#00', valid: {"12" => "12", "123" => "123", "1,234" => "1234", "1,234,567" => "1234567"}, invalid: %w(1 1234 12,34 12,34,567)},
      '#0.#'       => {pattern: '#0.#', valid: %w(1 1.2 1234.5), invalid: %w(12.34 1,234.5)},
      '#0.0#,#'    => {pattern: '#0.0#,#', valid: {"12.3" => "12.3", "12.34" => "12.34", "12.34,5" => "12.345"}, invalid: %w(1 12.345 12.34,56,7 12.34,567)},
    }.each do |name, props|
      context name do
        let(:pattern) {props[:pattern]}
        let(:groupChar) {props.fetch(:groupChar, ',')}
        let(:decimalChar) {props.fetch(:decimalChar, '.')}

        describe "valid" do
          case props[:valid]
          when Hash
            props[:valid].each do |value, result|
              it "with #{props[:pattern].inspect} #{value.inspect} => #{result.inspect}" do
                expect(subject.parse_uax35_number(pattern, value, groupChar, decimalChar)).to eql result
              end
            end
          when Array
            props[:valid].each do |value|
              it "with #{props[:pattern].inspect} #{value.inspect} => #{value.inspect}" do
                expect(subject.parse_uax35_number(pattern, value, groupChar, decimalChar)).to eql value
              end
            end
          end
        end
        describe "invalid" do
          Array(props[:invalid]).each do |value|
            it "with #{props[:pattern].inspect} #{value.inspect} invalid" do
              expect {subject.parse_uax35_number(pattern, value, groupChar, decimalChar)}.to raise_error RDF::Tabular::UAX35::ParseError
            end
          end
        end

        it "recognizes bad pattern #{pattern.inspect}" do
          expect{subject.parse_uax35_number(pattern, "", groupChar, decimalChar)}.to raise_error(ArgumentError)
        end if props[:exception]
      end
    end
  end

  describe "#build_number_re" do
    {
      '0'          => {valid: %w(1 -1 +1 12), invalid: %w(1.2), base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,})(?<suffix>)$/},
      '00'         => {valid: %w(12 123), invalid: %w(1 1,2), base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{2,})(?<suffix>)$/},
      '#'          => {valid: %w(1 12 123), invalid: %w(1.2), base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{0,})(?<suffix>)$/},
      '##'         => {re: /^(?<prefix>[+-]?)(?<numeric_part>\d{0,})(?<suffix>)$/},
      '#0'         => {re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,})(?<suffix>)$/},

      '0.0'         => {valid: %w(1.1 -1.1 12.1), invalid: %w(1.12), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{1})(?<suffix>)$/},
      '0.00'        => {valid: %w(1.12 +1.12 12.12), invalid: %w(1.1 1.123), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{2})(?<suffix>)$/},
      '0.#'         => {valid: %w(1 1.1 12.1), invalid: %w(1.12), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}(?:\.\d{0,1})?)(?<suffix>)$/},
      '-0'         => {valid: %w(-1 -10), invalid: %w(1 +1), base: "decimal", re: /^(?<prefix>\-)(?<numeric_part>\d{1,})(?<suffix>)$/},
      '%000'       => {valid: %w(%123 %+123 %-123 %1234), invalid: %w(%12 123%), base: "decimal", re: /^(?<prefix>%[+-]?)(?<numeric_part>\d{3,})(?<suffix>)$/},
      '‰000'       => {valid: %w(‰123 ‰+123 ‰-123 ‰1234), invalid: %w(‰12 123‰), base: "decimal", re: /^(?<prefix>‰[+-]?)(?<numeric_part>\d{3,})(?<suffix>)$/},
      '000%'       => {valid: %w(123% +123% -123% 1234%), invalid: %w(12% %123), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{3,})(?<suffix>%)$/},
      '000‰'       => {valid: %w(123‰ +123‰ -123‰ 1234‰), invalid: %w(12‰ ‰123), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{3,})(?<suffix>‰)$/},
      '000.0%'     => {base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{3,}\.\d{1})(?<suffix>%)$/},

      '###0.#####' => {valid: %w(1 1.1 12345.12345), invalid: %w(1,234.1 1.123456), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}(?:\.\d{0,5})?)(?<suffix>)$/},
      '###0.0000#' => {valid: %w(1.1234 1.12345 12345.12345), invalid: %w(1,234.1234 1.12), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{4,5})(?<suffix>)$/},
      '00000.0000' => {valid: %w(12345.1234), invalid: %w(1.2 1,234.123,4), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{5,}\.\d{4})(?<suffix>)$/},

      '#0.0#E#0'   => {base: "double", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{1,2}E[+-]?\d{1,2})(?<suffix>)$/},
      '#0.0#E+#0'   => {base: "double", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{1,2}E\+\d{1,2})(?<suffix>)$/},
      '#0.0#E#0%'  => {base: "double", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{1,2}E[+-]?\d{1,2})(?<suffix>%)$/},

      # Grouping
      '#,##,##0'   => {base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:(?:(?:\d{1,2},)?(?:\d{2},)*\d)?\d)?\d{1})(?<suffix>)$/},
      '#,##,#00'   => {base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:(?:\d{1,2},)?(?:\d{2},)*\d)?\d{2})(?<suffix>)$/},
      '#,##,000'   => {base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:\d{1,2},)?(?:\d{2},)*\d{3})(?<suffix>)$/},
      '#,#0,000'   => {base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:(?:\d{1,2},)?(?:\d{2},)*\d)?\d{1},\d{3})(?<suffix>)$/},
      '#,00,000'   => {base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:\d{1,2},)?(?:\d{2},)*\d{2},\d{3})(?<suffix>)$/},
      '0,00,000'   => {base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:(?:\d{1,2},)?(?:\d{2},)*\d)?\d{1},\d{2},\d{3})(?<suffix>)$/},

      '0.0##,###'  => {base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{1}(?:\d(?:\d(?:,\d(?:\d(?:\d)?)?)?)?)?)(?<suffix>)$/},
      '0.00#,###'  => {base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{2}(?:\d(?:,\d(?:\d(?:\d)?)?)?)?)(?<suffix>)$/},
      '0.000,###'  => {base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{3}(?:,\d(?:\d(?:\d)?)?)?)(?<suffix>)$/},
      '0.000,0##'  => {base: "decimal", re:/^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{3},\d{1}(?:\d(?:\d)?)?)(?<suffix>)$/},
      '0.000,00#'  => {base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{3},\d{2}(?:\d)?)(?<suffix>)$/},
      '0.000,000'  => {base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{3},\d{3})(?<suffix>)$/},

      # Jeni's
      '##0'        => {valid: %w(1 12 123 1234), invalid: %w(1,234 123.4), base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,})(?<suffix>)$/},
      '#,#00'      => {valid: %w(12 123 1,234 1,234,567), invalid: %w(1 1234 12,34 12,34,567), base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:(?:\d{1,3},)?(?:\d{3},)*\d)?\d{2})(?<suffix>)$/},
      '#0.#'       => {valid: %w(1 1.2 1234.5), invalid: %w(12.34 1,234.5), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}(?:\.\d{0,1})?)(?<suffix>)$/},
      '#0.0#,#'    => {valid: %w(12.3 12.34 12.34,5), invalid: %w(1 12.345 12.34,56,7 12.34,567), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{1}(?:\d(?:,\d)?)?)(?<suffix>)$/},
    }.each do |pattern, props|
      context pattern do
        it "generates #{props[:re]} for #{pattern}" do
          expect(subject.build_number_re(pattern, ",", ".")).to eql props[:re]
        end if props[:re].is_a?(Regexp)

        it "recognizes bad pattern #{pattern}" do
          expect{subject.build_number_re(pattern, ",", ".")}.to raise_error(ArgumentError)
        end if props[:re] == ArgumentError
      end
    end
  end
end
