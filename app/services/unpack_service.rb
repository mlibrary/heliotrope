# frozen_string_literal: true

class UnpackService
  def self.root_path_from_noid(noid, kind)
    Hyrax::DerivativePath.new(noid).derivative_path + kind
  end

  def self.noid_from_root_path(root_path, kind)
    root_path.gsub(/-#{kind}$/, '').split('/').slice(-5, 5).join('')
  end
end
