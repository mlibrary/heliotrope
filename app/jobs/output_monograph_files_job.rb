# frozen_string_literal: true

class OutputMonographFilesJob < ApplicationJob
  def perform(noid, path) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    monograph = Sighrax.from_noid(noid)

    monograph.children.each do |member|
      presenter = Sighrax.hyrax_presenter(member)
      unless presenter.external_resource_url.present? || presenter.file_size.blank? || presenter.file_size.zero?
        filename = CGI.unescape(presenter&.original_name&.first)
        if filename.present?
          begin
            File.open File.join(path, filename), "wb" do |dest|
              FileSet.find(member.noid).original_file.stream.each { |chunk| dest.write(chunk) }
            end
          rescue NoMemoryError => e
            Rails.logger.error "OutputMonographFilesJob failed with NoMemoryError: #{e}"
          end
        end
      end

      write_metadata_files(member, path)
    end
  end

  private

    def write_metadata_files(member, path)
      file_set = FileSet.find(member.noid)
      METADATA_FIELDS.select { |field| field[:object] == :file_set && field[:multivalued] == :yes_file }.each do |field|
        values = file_set.public_send(field[:metadata_name]).to_a
        WebvttService.export_filenames(member.noid, field[:metadata_name], values).each_with_index do |filename, index|
          File.write(File.join(path, filename), values[index])
        end
      end
    end
end
