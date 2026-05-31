# frozen_string_literal: true

module Keycard::Request
  # This class extracts attributes for Shibboleth-enabled applications.
  # It trusts specific HTTP headers, so the app must not be exposed to direct
  # requests. The pid is typically a SAML2 Persistent NameID, which is very
  # long and cumbersome. The presence of an eid depends on attribute release
  # by the IdP, and will commonly be an eduPersonPrincipalName. The only two
  # attributes guaranteed to have usable values are the client_ip, for all
  # requests, and the user_pid, for requests from authenticated users.
  class ShibbolethAttributes < Attributes
    def base
      super.merge(
        {
          persistentNameID: persistent_id,
          eduPersonPrincipalName: principal_name,
          eduPersonScopedAffiliation: affiliation,
          displayName: display_name,
          mail: email,
          authnContextClassRef: authn_context,
          authenticationMethod: authn_method,
          identity_provider: identity_provider
        }
      )
    end

    def user_pid
      persistent_id
    end

    def user_eid
      principal_name
    end

    def client_ip
      safe("HTTP_X_FORWARDED_FOR").split(",").first
    end

    def persistent_id
      get "HTTP_X_SHIB_PERSISTENT_ID"
    end

    def principal_name
      get "HTTP_X_SHIB_EDUPERSONPRINCIPALNAME"
    end

    def display_name
      get "HTTP_X_SHIB_DISPLAYNAME"
    end

    def email
      get "HTTP_X_SHIB_MAIL"
    end

    def affiliation
      safe("HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION").split(";")
    end

    def authn_method
      get "HTTP_X_SHIB_AUTHENTICATION_METHOD"
    end

    def authn_context
      get "HTTP_X_SHIB_AUTHNCONTEXT_CLASS"
    end

    def identity_provider
      get "HTTP_X_SHIB_IDENTITY_PROVIDER"
    end

    def identity_keys
      %i[user_pid user_eid eduPersonScopedAffiliation]
    end
  end
end
