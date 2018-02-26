# frozen_string_literal: true

# Bill Deuber pointed to this solution for faking the request headers in
# development and testing environments.
#
# The reason to do this in the testing environment is to short circuit
# calls to external servers.
#
# The reason to do this in the developement environment is the same as testing
# plus it allows the developer to login in as different personas.
#
# The reason an environment variable is used is because this code is plain old ruby
# and has no connection to the rails app.
#
# Only add this middleware for those environments: in development.rb and test.rb
# under config/environments/ config.middleware.use "FakeAuthHeader"

class FakeAuthHeader
  def initialize(app)
    @app = app
  end

  def call(env)
    dup._call(env)
  end

  # duplicating the object to make sure ivars aren't set on the original.
  # consideration for threads. different threads can have their own object
  # (a duped copy) and carry on their merry way.
  def _call(env)
    env['HTTP_X_REMOTE_USER'] = ENV['FAKE_HTTP_X_REMOTE_USER']
    @app.call(env)
  end
end
