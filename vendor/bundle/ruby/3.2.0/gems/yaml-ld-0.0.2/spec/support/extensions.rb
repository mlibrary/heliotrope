class Object
  def equivalent_structure?(other, ordered: false)
    self == other
  end
end

class Hash
  def equivalent_structure?(other, ordered: false)
    return false unless other.is_a?(Hash) && other.length == length
    all? do |key, value|
      # List values are still ordered
      if key == '@language' && value.is_a?(String)
        value.downcase.equivalent_structure?(other[key].to_s.downcase, ordered: key == '@list')
      else
        value.equivalent_structure?(other[key], ordered: key == '@list')
      end
    end
  end

  def diff(other)
    self.keys.inject({}) do |memo, key|
      unless self[key] == other[key]
        memo[key] = [self[key], other[key]] 
      end
      memo
    end
  end
end

class Array
  def equivalent_structure?(other, ordered: false)
    return false unless other.is_a?(Array) && other.length == length
    if ordered
      b = other.dup
      # All elements must match in order
      all? {|av| av.equivalent_structure?(b.shift)}
    else
      # Look for any element which matches
      all? do |av|
        other.any? {|bv| av.equivalent_structure?(bv)}
      end
    end
  end
end
