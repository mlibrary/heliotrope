# frozen_string_literal: true

class OutputMonographFilesJob < ApplicationJob
  # @param [noid] NOID of Monograph whose files are being extracted
  # @param [path] string, path of directory to extract to
  def perform(noid, path)
    monograph = Sighrax.from_noid(noid)

    monograph.children.each do |member|
      presenter = Sighrax.hyrax_presenter(member)

      # The importer is written to exit on zero-size files. We shouldn't have any in the system in future, see:
      # https://tools.lib.umich.edu/jira/browse/HELIO-2246
      next if presenter.external_resource_url.present? || presenter.file_size.blank? || presenter.file_size.zero?
      filename = CGI.unescape(presenter&.original_name&.first)
      next if filename.blank?

      begin
        File.open File.join(path, filename), "wb" do |dest|
          FileSet.find(member.noid).original_file.stream.each { |chunk| dest.write(chunk) }
        end
      rescue NoMemoryError => e
        Rails.logger.error "OutputMonographFilesJob failed with NoMemoryError: #{e}"
      end
    end
  end
end
