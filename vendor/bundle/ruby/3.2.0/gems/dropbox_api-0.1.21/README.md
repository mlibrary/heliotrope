# DropboxApi

Library for communicating with Dropbox API v2.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dropbox_api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dropbox_api

## Documentation

Please, refer to this gem's custom [Dropbox API
documentation](http://jesus.github.io/dropbox_api).
Most of the time you'll be checking the [available
endpoints](http://jesus.github.io/dropbox_api/DropboxApi/Client.html).

Unfortunately, the documentation at [RubyDoc.info](http://www.rubydoc.info) is
disrecommended because it lacks some nice features that have been added with
YARD plugins:

- Each endpoint includes its tests right below the description, this works as
  an example of its usage.
- All endpoints are shown as methods of the `Client` class, just as you will
  use them.

## Basic set up

### Authorize your application

Dropbox uses OAuth, in order to use this library from your application you'll
have to get an authorization code.

Once you have it, just pass it on client initialization:

```ruby
DropboxApi::Client.new("VofXAX8D...")
#=> #<DropboxApi::Client ...>
```

Or set it as an ENV variable called `DROPBOX_OAUTH_BEARER`, for example:

```ruby
ENV["DROPBOX_OAUTH_BEARER"] = "VofXAX8D..."
DropboxApi::Client.new
#=> #<DropboxApi::Client ...>
```

The official documentation on the process to get an authorization code is
[here](https://developers.dropbox.com/es-es/oauth-guide#implementing-oauth),
it describes the two options listed below.


#### Option A: Get your access token from the website

For a quick test, you can obtain an access token from the App Console in
[Dropbox's website](https://www.dropbox.com/developers/). Select from
*My apps* your application, you may need to create one if you
haven't done so yet. Under your application settings, find section
*OAuth 2*, there is a button to generate an access token.

#### Option B: OAuth2 Code Flow

This is typically what you will use in production, you can obtain an
authorization code with a 3-step process:

```ruby
# 1. Get an authorization URL.
authenticator = DropboxApi::Authenticator.new(CLIENT_ID, CLIENT_SECRET)
authenticator.auth_code.authorize_url #=> "https://www.dropbox.com/..."

# 2. Log into Dropbox and authorize your app. You need to open the
# authorization URL in your browser.

# 3. Exchange the authorization code for a reusable access token (not visible
#    to the user).
access_token = authenticator.auth_code.get_token(CODE) #=> #<OAuth2::AccessToken ...>`
access_token.token #=> "VofXAX8D..."

# Keep this token, you'll need it to initialize a `DropboxApi::Client` object:
client = DropboxApi::Client.new(access_token: access_token)

# For backwards compatibility, the following also works:
client = DropboxApi::Client.new(access_token.token)
```

##### Integration with Rails

If you have a Rails application, you might be interested in this [setup
guide](http://jesus.github.io/dropbox_api/file.rails_setup.html).


##### Using refresh tokens

Access tokens are short-lived by default (as of September 30th, 2021),
applications that require long-lived access to the API without additional
interaction with the user should use refresh tokens.

The process is similar but a token refresh might seamlessly occur as you
perform API calls. When this happens you'll need to store the
new token hash if you want to continue using this session, you can use the
`on_token_refreshed` callback to do this.

```ruby
# 1. Get an authorization URL, requesting offline access type.
authenticator = DropboxApi::Authenticator.new(CLIENT_ID, CLIENT_SECRET)
authenticator.auth_code.authorize_url(token_access_type: 'offline')

# 2. Log into Dropbox and authorize your app. You need to open the
#    authorization URL in your browser.

# 3. Exchange the authorization code for a reusable access token
access_token = authenticator.auth_code.get_token(CODE) #=> #<OAuth2::AccessToken ...>`

# You can now use the access token to initialize a DropboxApi::Client, you
# should also provide a callback function to store the updated access token
# whenever it's refreshed.
client = DropboxApi::Client.new(
  access_token: access_token,
  on_token_refreshed: lambda { |new_token_hash|
    # token_hash is a serializable Hash, something like this:
    # {
    #   "uid"=>"440",
    #   "token_type"=>"bearer",
    #   "scope"=>"account_info.read account_info.write...",
    #   "account_id"=>"dbid:AABOLtA1rT6rRK4vajKZ...",
    #   :access_token=>"sl.A5Ez_CBsqJILhDawHlmXSoZEhLZ4nuLFVRs6AJ...",
    #   :refresh_token=>"iMg4Me_oKYUAAAAAAAAAAapQixCgwfXOxuubCuK_...",
    #   :expires_at=>1632948328
    # }
    SomewhereSafe.save(new_token_hash)
  }
)
```

Once you've gone through the process above, you can skip the steps that require
user interaction in subsequent initializations of `DropboxApi::Client`. For
example:

```ruby
# 1. Initialize an authenticator
authenticator = DropboxApi::Authenticator.new(CLIENT_ID, CLIENT_SECRET)

# 2. Retrieve the token hash you previously stored somewhere safe, you can use
#    it to build a new access token.
access_token = OAuth2::AccessToken.from_hash(authenticator, token_hash)

# 3. You now have an access token, so you can initialize a client like you
#    would normally:
client = DropboxApi::Client.new(
  access_token: access_token,
  on_token_refreshed: lambda { |new_token_hash|
    SomewhereSafe.save(new_token_hash)
  }
)
```

### Performing API calls

Once you've initialized a client, for example:

```ruby
client = DropboxApi::Client.new("VofXAX8D...")
#=> #<DropboxApi::Client ...>
```

You can perform an API call like this:

```ruby
result = client.list_folder "/sample_folder"
#=> #<DropboxApi::Results::ListFolderResult>
result.entries
#=> [#<DropboxApi::Metadata::Folder>, #<DropboxApi::Metadata::File>]
result.has_more?
#=> false
```

The instance of `Client` we've initialized is the one you'll be using to
perform API calls. You can check the class' documentation to find
[all available endpoints](http://jesus.github.io/dropbox_api/DropboxApi/Client.html).

### Large file uploads

If you need to upload files larger than 150MB the default `#upload` endpoint
won't work. Instead, you need to start a upload session and upload
the file in small chunks.

To make this easier, the method `upload_by_chunks` will handle this for you,
example:

```ruby
client = DropboxApi::Client.new("VofXAX8D...")
#=> #<DropboxApi::Client ...>
File.open("large_file.avi") do |f|
  client.upload_by_chunks "/remote_path.txt", f
end
```

Check out the
[method documentation](http://www.xuuso.com/dropbox_api/DropboxApi/Client.html#upload_by_chunks-instance_method)
to find out all available options.

### Accessing Team Folders

In order to access your team scope you need to add the namespace_id to you request headers.
This can be done using the middlewere layer as per the below:

```ruby
client = DropboxApi::Client.new("VofXAX8D...")
#=> #<DropboxApi::Client ...>
client.namespace_id = client.get_current_account.root_info.root_namespace_id

client.list_folder('')
#=> Now returns the team folders
```

You could unset the namespace ID at any point afterwards with just:

```ruby
client.namespace_id = nil
```

## Dependencies

This gem depends on
[oauth2](https://github.com/oauth-xx/oauth2)
and
[faraday](https://github.com/lostisland/faraday).

It has official support for Ruby versions `2.x`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/console` for an interactive prompt that will allow you to experiment.

### Testing

I recommend you to use a test account other than your main one.

We use VCR to record the HTTP calls to Dropbox, however we sometimes need to
regenerate the cassettes. Let's take `list_folder` as an example to show what
would be the procedure to do so:

 1. Manually delete the existing cassettes in
    `spec/fixtures/vcr_cassettes/list_folder/*.yml`.

 2. Run the task to build the scaffolding in your Dropbox account so the tests
    will pass. If it doesn't exist you may need to write it yourself, check
    the `DropboxScaffoldBuilder` class to find all existing scaffold builders.

    ```text
    DROPBOX_OAUTH_BEARER=YOUR_AUTH_BEARER rake test:build_scaffold[list_folder]
    ```

    Note that you'll have to type `rake test:build_scaffold\[list_folder\]`
    if you use `zsh`.

    You can build all available scaffolds with just `rake test:build_scaffold`.

 3. Run the tests and the cassettes will be written:

    ```text
    DROPBOX_OAUTH_BEARER=YOUR_AUTH_BEARER rspec spec/endpoints/files/list_folder_spec.rb
    ```

The OAuth bearer shouldn't have been recorded in the cassette and it should've
been filtered. However, you may want to double check before pushing your
updates to Github.

Tip: you can simply run `export DROPBOX_OAUTH_BEARER=YOUR_AUTH_BEARER` at
the beginning of your work session so you don't need to prefix it in every
command line.

## Contributing

Any help will be much appreciated. The easiest way to help is to implement one
or more of the [endpoints that are still pending](http://jesus.github.io/dropbox_api/file.api_coverage.html). To see how the
endpoints are implemented, check out the `lib/dropbox_api/endpoints` folder.
