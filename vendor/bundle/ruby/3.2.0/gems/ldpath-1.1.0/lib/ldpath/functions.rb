# rubocop:disable Style/MethodName
module Ldpath
  module Functions
    def concat(_uri, _context, *args)
      deep_flatten_compact(*args).to_a.join
    end

    def first(_uri, _context, *args)
      deep_flatten_compact(*args).first
    end

    def last(_uri, _context, *args)
      deep_flatten_compact(*args).to_a.last
    end

    def count(_uri, _context, *args)
      deep_flatten_compact(*args).count
    end

    def eq(_uri, _context, *args)
      a, b, *rem = deep_flatten_compact(*args).first(3)
      raise "Too many arguments to fn:eq" unless rem.empty?

      a == b
    end

    def ne(_uri, _context, *args)
      a, b, *rem = deep_flatten_compact(*args).first(3)
      raise "Too many arguments to fn:ne" unless rem.empty?

      a != b
    end

    def lt(_uri, _context, *args)
      a, b, *rem = deep_flatten_compact(*args).first(3)
      raise "Too many arguments to fn:lt" unless rem.empty?

      a < b
    end

    def le(_uri, _context, *args)
      a, b, *rem = deep_flatten_compact(*args).first(3)
      raise "Too many arguments to fn:le" unless rem.empty?

      a <= b
    end

    def gt(_uri, _context, *args)
      a, b, *rem = deep_flatten_compact(*args).first(3)
      raise "Too many arguments to fn:gt" unless rem.empty?

      a > b
    end

    def ge(_uri, _context, *args)
      a, b, *rem = deep_flatten_compact(*args).first(3)
      raise "Too many arguments to fn:ge" unless rem.empty?

      a >= b
    end

    # collections
    def flatten(uri, context, lists)
      return to_enum(:flatten, uri, context, lists) unless block_given?

      deep_flatten_compact(lists).each do |x|
        RDF::List.new(subject: x, graph: context).to_a.each do |i|
          yield i
        end
      end
    end

    def get(uri, context, list, idx)
      idx = idx.respond_to?(:to_i) ? idx.to_i : idx.to_s.to_i

      flatten(uri, context, list).to_a[idx]
    end

    def subList(uri, context, list, idx_start, idx_end = nil)
      arr = flatten(uri, context, list).to_a

      idx_start = idx_start.respond_to?(:to_i) ? idx_start.to_i : idx_start.to_s.to_i
      idx_end &&= idx_end.respond_to?(:to_i) ? idx_end.to_i : idx_end.to_s.to_i

      if idx_end
        arr[(idx_start.to_i..(idx_end - idx_start))]
      else
        arr.drop(idx_start)
      end
    end

    # dates

    def earliest(_uri, _context, *args)
      deep_flatten_compact(*args).min
    end

    def latest(_uri, _context, *args)
      deep_flatten_compact(*args).max
    end

    # math

    def min(_uri, _context, *args)
      deep_flatten_compact(*args).min
    end

    def max(_uri, _context, *args)
      deep_flatten_compact(*args).max
    end

    def round(_uri, _context, *args)
      deep_flatten_compact(*args).map do |i|
        i.respond_to?(:round) ? i.round : i
      end
    end

    def sum(_uri, _context, *args)
      args.inject(0) { |acc, elem| acc + elem }
    end

    # text

    def replace(_uri, _context, str, pattern, replacement)
      regex = Regexp.parse(pattern)
      Array(str).map do |x|
        x.gsub(regex, replacement)
      end
    end

    def strlen(_uri, _context, str)
      Array(str).map(&:length)
    end

    def wc(_uri, _context, str)
      Array(str).map { |x| x.split.length }
    end

    def strLeft(_uri, _context, str, left)
      Array(str).map { |x| x[0..left.to_i] }
    end

    def strRight(_uri, _context, str, right)
      Array(str).map { |x| x[right.to_i..x.length] }
    end

    def substr(_uri, _context, str, left, right)
      Array(str).map { |x| x[left.to_i..right.to_i] }
    end

    def strJoin(_uri, _context, str, sep = "", prefix = "", suffix = "")
      prefix + Array(str).join(sep) + suffix
    end

    def equals(_uri, _context, str, other)
      Array(str).map { |x| x == other }
    end

    def equalsIgnoreCase(_uri, _context, str, other)
      Array(str).map { |x| x.casecmp(other) }
    end

    def contains(_uri, _context, str, substr)
      Array(str).map { |x| x.include? substr }
    end

    def startsWith(_uri, _context, str, suffix)
      Array(str).map { |x| x.start_with? suffix }
    end

    def endsWith(_uri, _context, str, suffix)
      Array(str).map { |x| x.end_with? suffix }
    end

    def isEmpty(_uri, _context, str)
      Array(str).map(&:empty?)
    end

    def predicates(uri, context, *_args)
      context.query([uri, nil, nil]).map(&:predicate).uniq
    end

    def xpath(_uri, _context, xpath, node)
      x = Array(xpath).flatten.first
      Array(node).flatten.compact.map do |n|
        Nokogiri::XML(n.to_s).xpath(x.to_s, prefixes.map { |k, v| [k, v.to_s] }).map(&:text)
      end
    end

    private

    def deep_flatten_compact(*args)
      return to_enum(:deep_flatten_compact, *args) unless block_given?

      args.each do |x|
        if x.is_a? Enumerable
          x.each { |y| yield y unless y.nil? }
        else
          yield x unless x.nil?
        end
      end
    end
  end
end
