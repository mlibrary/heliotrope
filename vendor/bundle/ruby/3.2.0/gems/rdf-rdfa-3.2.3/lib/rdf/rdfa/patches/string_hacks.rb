class ::String
  # Trim beginning of each line by the amount of indentation in the first line
  def align_left
    str = self.sub(/^\s*$/, '')  # Remove leading newline
    str = str[1..-1] if str[0,1] == "\n"
    ws = str.match(/^(\s*)\S/m) ? $1 : ''
    str.gsub(/^#{ws}/m, '')
  end
end
