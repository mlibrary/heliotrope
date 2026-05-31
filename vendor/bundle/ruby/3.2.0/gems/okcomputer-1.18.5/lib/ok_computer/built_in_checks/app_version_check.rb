module OkComputer
  # Display app version SHA
  #
  # * If `ENV["SHA"]` is set, uses that value.
  # * Otherwise, checks for Capistrano's REVISION file in the app root.
  # * Failing these, the check fails
  class AppVersionCheck < Check
    attr_accessor :file
    attr_accessor :env
    attr_accessor :transform

    # Public: Initialize a check for a backed-up Sidekiq queue
    #
    # file - The path of the version file to check
    # env - The key in ENV to check for a revision SHA
    # transform - The block to optionally transform the version string
    def initialize(file: "REVISION", env: "SHA", &transform)
      self.file = file
      self.env = env
      self.transform = transform || proc { |v| v }
    end

    # Public: Return the application version
    def check
      mark_message "Version: #{version}"
    rescue UnknownRevision
      mark_failure
      mark_message "Unable to determine version"
    end

    # Public: The application version
    #
    # Returns a String
    def version
      transform.call(version_from_env || version_from_file || raise(UnknownRevision))
    end

    private

    # Private: Version stored in environment variable
    def version_from_env
      ENV[env]
    end

    # Private: Version stored in Capistrano revision file
    def version_from_file
      path = Rails.root.join(file)
      File.read(path).chomp if File.exist?(path)
    end

    UnknownRevision = Class.new(StandardError)
  end
end
