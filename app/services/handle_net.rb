# frozen_string_literal: true

class HandleNet
  DOI_ORG_PREFIX = 'https://doi.org/'
  HANDLE_NET_PREFIX = 'https://hdl.handle.net/'
  FULCRUM_HANDLE_PREFIX = '2027/fulcrum.'

  class << self
    def noid(handle_path_or_url)
      match = /^(#{Regexp.escape(HANDLE_NET_PREFIX)})?(#{Regexp.escape(FULCRUM_HANDLE_PREFIX)})(.*)$/i.match(handle_path_or_url || "")
      return nil if match.nil?
      noid = /^[[:alnum:]]{9}$/i.match(match[3])
      return match[3] unless noid.nil?
      noid = /^([[:alnum:]]{9})\?(.*)$/i.match(match[3])
      return nil if noid.nil?
      noid[1]
    end

    def path(noid)
      FULCRUM_HANDLE_PREFIX + noid.to_s
    end

    def url(noid)
      HANDLE_NET_PREFIX + path(noid)
    end

    def value(noid)
      return nil unless Settings.handle_service&.instantiate

      HandleRest::UrlService.new(1, HandleNet.service).get(HandleNet.path(noid))
    rescue StandardError => e
      Rails.logger.error("HandleNet.value(#{noid}) failed with error #{e}")
      nil
    end

    def create_or_update(noid, url)
      return false unless Settings.handle_service&.instantiate

      HandleRest::UrlService.new(1, HandleNet.service).set(HandleNet.path(noid), url)
      true
    rescue StandardError => e
      Rails.logger.error("HandleNet.create_or_update(#{noid}, #{url}) failed with error #{e}")
      false
    end

    def delete(noid)
      return false unless Settings.handle_service&.instantiate

      HandleNet.service.delete(HandleRest::Handle.from_s(HandleNet.path(noid)))
      true
    rescue StandardError => e
      Rails.logger.error("HandleNet.delete(#{noid}) failed with error #{e}")
      false
    end

    def service
      return nil unless Settings.handle_service&.instantiate

      root_admin = HandleRest::Identity.from_s("300:0.NA/2027")
      root_admin_value = HandleRest::AdminValue.new(root_admin.index, HandleRest::AdminPermissionSet.new, root_admin.handle)
      root_admin_value_line = HandleRest::ValueLine.new(100, root_admin_value)

      local_admin = HandleRest::Identity.from_s("300:2027/spo")
      local_admin_value = HandleRest::AdminValue.new(local_admin.index, HandleRest::AdminPermissionSet.new, local_admin.handle)
      local_admin_value_line = HandleRest::ValueLine.new(101, local_admin_value)

      HandleRest::Service.new([root_admin_value_line, local_admin_value_line], Services.handle_service)
    end
  end
end
