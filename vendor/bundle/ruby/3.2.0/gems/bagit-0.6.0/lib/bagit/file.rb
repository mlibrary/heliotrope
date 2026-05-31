# frozen_string_literal: true

class File
  # Clean out all the empty dirs
  def self.clean(file_name)
    return unless File.directory? file_name
    # clean all subdirs
    subdirs = Dir.entries(file_name).select { |p| File.directory?(File.join(file_name, p)) }
    subdirs.reject! { |p| %w[. ..].include? p }
    subdirs.each { |sd| File.clean File.join(file_name, sd) }

    # if its empty then delete it
    contents = Dir.entries(file_name).reject { |p| %w[. ..].include? p }
    Dir.delete file_name if contents.empty?
  end
end
