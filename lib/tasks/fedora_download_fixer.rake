# frozen_string_literal: true

# See HELIO-4381

desc 'create a new Monograph and attached FileSet if Fedora shows download problems'
namespace :heliotrope do
  task fedora_download_fixer: :environment do
    # https://stackoverflow.com/a/55011187
    include StatusPageService

    fedora_status = false

    begin
      retries ||= 1
      puts "#{Time.now.iso8601} ... Checking for Fedora 200 response: try ##{ retries }"

      if fedora == 'UP'
        fedora_status = true
        puts "#{Time.now.iso8601} ... Fedora is UP."
      else
        raise "#{Time.now.iso8601} ... Fedora not up yet!"
      end
    rescue
      # max 300 seconds spent checking for Fedora to come back up
      if (retries += 1) <= 30
        sleep 10
        retry
      end
    end

    unless fedora_status
      puts "----------------------------------------------------------------------------------"
      exit
    end

    # In theory there is a small chance this would always be true if the first FileSet added to Fedora was an...
    # external resource, but it's very unlikely and this makes things easier than creating a dedicated test FileSet.
    if FileSet.first.original_file == nil
      puts "#{Time.now.iso8601} ... FileSet.first.original_file is nil! Creating new Monograph with FileSet!"
      monograph = Monograph.new(title: ["Debian 11 upgrade download fix Monograph (created #{Time.now.iso8601})"],
                                press: 'heliotrope')
      monograph.save

      file_set = FileSet.new(title: ["Debian 11 upgrade download fix FileSet (created #{Time.now.iso8601})"])
      file_set.save

      monograph.ordered_members << file_set
      monograph.save
    else
      puts "#{Time.now.iso8601} ... FileSet.first.original_file is not nil. Exiting."
      puts "----------------------------------------------------------------------------------"
    end
  end
end
