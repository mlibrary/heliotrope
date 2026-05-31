# @title Rails setup

# Standard OAuth 2 flow set up

This document describes how to implement the OAuth2 flow in a Rails
application, the process is represented in the following diagram:

![Oauth 2 flow](https://www.dropbox.com/static/images/developers/oauth2-web-diagram.png)

Source: [https://www.dropbox.com/developers/reference/oauth-guide#oauth-2-on-the-web](https://www.dropbox.com/developers/reference/oauth-guide#oauth-2-on-the-web)

## 1. Set up some new routes

You'll have to create a couple of new routes:

```ruby
get 'dropbox/auth' => 'dropbox#auth'
get 'dropbox/auth_callback' => 'dropbox#auth_callback'
```

We'll use `dropbox/auth` to perform the step 2 in the diagram, i.e. this route
will redirect to Dropbox.

The other route, `dropbox/auth_callback`, will process the authentication token
that we'll receive from Dropbox. Steps 4 & 5.

## 2. Set up a Dropbox controller

```ruby
class DropboxController < ApplicationController
  # Example call:
  # GET /dropbox/auth
  def auth
    url = authenticator.authorize_url :redirect_uri => redirect_uri

    redirect_to url
  end

  # Example call:
  # GET /dropbox/auth_callback?code=VofXAX8DO1sAAAAAAAACUKBwkDZyMg1zKT0f_FNONeA
  def auth_callback
    auth_bearer = authenticator.get_token(params[:code],
                                          :redirect_uri => redirect_uri)
    token = auth_bearer.token # This line is step 5 in the diagram.

    # At this stage you may want to persist the reusable token we've acquired.
    # Remember that it's bound to the Dropbox account of your user.

    # If you persist this token, you can use it in subsequent requests or
    # background jobs to perform calls to Dropbox API such as the following.
    folders = DropboxApi::Client.new(token).list_folder "/"
  end

  private

  def authenticator
    client_id = "az8ykn83kecoodq"
    client_secret = "ozp1pxo8e563fc5"

    DropboxApi::Authenticator.new(client_id, client_secret)
  end

  def redirect_uri
    dropbox_auth_callback_url # => http://localhost:3000/dropbox/auth_callback
  end
end
```

## 3. Set up redirect URI in your Dropbox app settings

In the previous code, you probably noticed that we're providing a `redirect_uri`
parameter. This is where the user will be redirected to after accepting our
application.

However, Dropbox will only redirect to a set of whitelisted URIs, so
you'll need to add yours to the list. That's very easy:

1. Log in to your Dropbox developer account at
   [www.dropbox.com/developers](https://www.dropbox.com/developers).
2. On the menu, click on "My Apps". Then click on your application to edit its
   settings.
4. On the OAuth 2 section, add the redirect URI that maps to the
   `auth_callback` method that we've implemented above. For example,
   `www.yourapp.com/dropbox/oauth_callback`.
