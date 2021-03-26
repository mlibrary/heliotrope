# frozen_string_literal: true

require 'bagit'
require 'aws-sdk-s3'
require 'active_support'
require 'active_support/time'
ENV["TZ"] = "US/Eastern"

class AptrustDepositJob < ApplicationJob
  def perform(monograph_id)
    monograph = Sighrax.from_noid(monograph_id)
    return false unless monograph.is_a?(Sighrax::Monograph)

    Dir.mktmpdir(["deposit", monograph.noid], Rails.root.join('tmp')) do |dir|
      Dir.chdir(dir) do
        success = false
        begin
          AptrustDeposit.find_by(noid: monograph_id)&.delete
          success = deposit(tar(bag(monograph)))
          AptrustDeposit.create(noid: monograph_id, identifier: identifier(monograph)) if success
        rescue StandardError => e
          Rails.logger.error("AptrustDepositJob(#{monograph_id} #{e}")
          success = false
        end
        success
      end
    end
  end

  def identifier(monograph)
    "fulcrum.org.#{Sighrax.press(monograph).subdomain}-#{monograph.noid}"
  end

  def bag(monograph)
    # Aptrust identifier
    dirname = identifier(monograph)

    # Make bag directory
    Dir.mkdir(dirname)

    # New bag
    bag = BagIt::Bag.new(File.join('.', dirname))

    # Create bagit-info.txt file
    bag.write_bag_info(bag_info(monograph))

    # Create aptrust-info.txt file
    File.write(File.join(bag.bag_dir, 'aptrust-info.txt'), aptrust_info(monograph), mode: 'w')

    # Extract monograph into data directory
    Export::Exporter.new(monograph.noid).extract("#{bag.bag_dir}/data/", true)

    # Create manifests
    bag.manifest!

    dirname
  end

  def bag_info(monograph)
    # add bagit-info.txt file
    # The length of the following 'internal_sender_description' does not work with the current bagit gem, maybe later.
    # pub = monograph_presenter.publisher.blank? ? '' : monograph_presenter.publisher.first.squish[0..55]
    # internal_sender_description = "This bag contains all of the data and metadata in a Monograph from #{pub} which has been exported from the Fulcrum publishing platform hosted at www.fulcrum.org."
    timestamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    time_i8601 = Time.parse(timestamp).iso8601
    {
      'Source-Organization' => 'University of Michigan',
      'Bag-Count' => '1',
      'Bagging-Date' => time_i8601,
      'Internal-Sender-Description' => "Bag for a monograph hosted at www.fulcrum.org",
      'Internal-Sender-Identifier' => monograph.noid
    }
  end

  def aptrust_info(monograph)
    # Add aptrust-info.txt file
    # this is text that shows up in the APTrust web interface
    # title, access, and description are required; Storage-Option defaults to Standard if not present
    monograph_presenter = Sighrax.hyrax_presenter(monograph)
    title = monograph_presenter.title.blank? ? '' : monograph_presenter.title.squish[0..255]
    publisher = monograph_presenter.publisher.blank? ? '' : monograph_presenter.publisher.first.squish[0..249]
    press = monograph_presenter.press.blank? ? '' : monograph_presenter.press.squish[0..249]
    description = monograph_presenter.description.first.blank? ? '' : monograph_presenter.description.first.squish[0..249]
    creator = monograph_presenter.creator.blank? ? '' : monograph_presenter.creator.first.squish[0..249]
    <<~INFO
      Title: #{title}
      Access: Institution
      Storage-Option: Standard
      Description: This bag contains all of the data and metadata related to a Monograph which has been exported from the Fulcrum publishing platform hosted at https://www.fulcrum.org. The data folder contains a Fulcrum manifest in the form of a CSV file named with the NOID assigned to this Monograph in the Fulcrum repository. This manifest is exported directly from Fulcrum's heliotrope application (https://github.com/mlibrary/heliotrope) and can be used for re-import as well. The first two rows contain column headers and human-readable field descriptions, respectively. {{ The final row contains descriptive metadata for the Monograph; other rows contain metadata for Resources, which may be components of the Monograph or material supplemental to it.}}
      Press-Name: #{publisher}
      Press: #{press}
      Item Description: #{description}
      Creator/Author: #{creator}
    INFO
  end

  def tar(dirname)
    filename = dirname + '.tar'
    Minitar.pack(dirname, File.open(filename, 'wb'))
    filename
  end

  def deposit(filename)
    success = false
    begin
      aptrust_yaml = Rails.root.join('config', 'aptrust.yml')
      aptrust = YAML.safe_load(File.read(aptrust_yaml))
      Aws.config.update(credentials: Aws::Credentials.new(aptrust['AwsAccessKeyId'], aptrust['AwsSecretAccessKey']))
      s3 = Aws::S3::Resource.new(region: aptrust['BucketRegion'])
      success = s3.bucket(aptrust['Bucket']).object(File.basename(filename)).upload_file(filename)
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "Upload of file #{filename} failed in #{e.context} with error #{e}"
      success = false
    end
    success
  end
end
