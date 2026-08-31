# frozen_string_literal: true

class UnpackService
  def self.root_path_from_noid(noid, kind)
    Hyrax::DerivativePath.new(noid).derivative_path + kind
  end

  def self.noid_from_root_path(root_path, kind)
    root_path.gsub(/-#{kind}$/, '').split('/').slice(-5, 5).join('')
  end

  def self.remove_path_from_noid(noid, kind)
    root_path = root_path_from_noid(noid, kind)
    root_path.sub(/\/*.-#{kind}/, '/') + "TO-BE-REMOVED-" + DateTime.now.to_i.to_s + "-#{kind}"
  end

  def self.safe_path(root_dir, relative_path)
    return nil if root_dir.blank? || relative_path.blank?

    expanded_root = File.expand_path(root_dir)
    target_root = expanded_root.end_with?(File::SEPARATOR) ? expanded_root : expanded_root + File::SEPARATOR
    expanded_path = File.expand_path(relative_path, expanded_root)

    return expanded_path if expanded_path.start_with?(target_root) && File.exist?(expanded_path)

    nil
  end
end
