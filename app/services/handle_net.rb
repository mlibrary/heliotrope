# frozen_string_literal: true

class HandleNet
  DOI_ORG_PREFIX = 'https://doi.org/'
  HANDLE_NET_PREFIX = 'https://hdl.handle.net/'
  # the standard Fulcrum handle for an object just appends the object's NOID after a namespacing value of 'fulcrum.'
  # 2027 is the handle prefix we use. We share this with HathiTrust, meaning there are ~18M handles under it.
  FULCRUM_HANDLE_PREFIX = '2027/fulcrum.'

  class << self
    # noid() is not used in handle generation, but rather as convenience method when calculating an object's NOID...
    # from the Fulcrum "standard" handle, which is used in embed codes etc.


    def full_handle_url(handle)
      HANDLE_NET_PREFIX + handle.to_s
    end

    def url_value_for_handle(handle)
      return nil unless Settings.handle_service&.instantiate

      HandleRest::UrlService.new(1, HandleNet.service).get(handle)
    rescue StandardError => e
      Rails.logger.error("HandleNet.url_value_for_handle(#{handle}) failed with error #{e}")
      nil
    end

    def create_or_update(handle, url)
      return false unless Settings.handle_service&.instantiate

      HandleRest::UrlService.new(1, HandleNet.service).set(handle, url)
      true
    rescue StandardError => e
      Rails.logger.error("HandleNet.create_or_update(#{handle}, #{url}) failed with error #{e}")
      false
    end

    def delete(handle)
      return false unless Settings.handle_service&.instantiate

      HandleNet.service.delete(HandleRest::Handle.from_s(handle))
      true
    rescue StandardError => e
      Rails.logger.error("HandleNet.delete(#{handle}) failed with error #{e}")
      false
    end

    def service
      return nil unless Settings.handle_service&.instantiate

      admin_group = HandleRest::Identity.from_s("200:0.NA/2027")
      # The admin permission set is twelve characters with the following order: add handle, delete handle, add
      # naming authority, delete naming authority, modify values, remove values, add values, read values,
      # modify administrator, remove administrator, add administrator and list handles.
      admin_permission_set = HandleRest::AdminPermissionSet.from_s("110011110011") # Yea! A palindrome
      admin_group_value = HandleRest::AdminValue.new(admin_group.index, admin_permission_set, admin_group.handle)
      admin_group_value_line = HandleRest::ValueLine.new(100, admin_group_value)

      HandleRest::Service.new([admin_group_value_line], Services.handle_service)
    end
  end
end
