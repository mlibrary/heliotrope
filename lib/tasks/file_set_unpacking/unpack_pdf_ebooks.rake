# frozen_string_literal: true

desc 'Unpack pdf_ebook FeaturedRepresentatives into /derivatives for HELIO-3058'
namespace :heliotrope do
  task unpack_pdf_ebooks: :environment do
    # This is for the intitial "migration" to pull pdfs out of fedora and onto
    # the file systems so x-sendfile and byte ranges work. So this task is
    # a one-off.
    FeaturedRepresentative.where(kind: 'pdf_ebook').each do |fr|
      f = FileSet.find(fr.file_set_id)
      next unless f.present?

      UnpackJob.perform_later(f.id, 'pdf_ebook')
      puts "Unpacking #{UnpackService.root_path_from_noid(f.id, 'pdf_ebook') + '.pdf'}"
    end
  end
end
