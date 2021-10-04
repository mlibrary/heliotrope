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
end
