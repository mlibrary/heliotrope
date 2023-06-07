# frozen_string_literal: true

module PdfPageIndexer
  def add(press, file_set_id)
    pdf = UnpackService.root_path_from_noid(file_set_id, 'pdf_ebook') + '.pdf'
    if pdf.blank?
      Rails.logger.info("No unpacked pdf_ebook found for #{file_set_id}")
      return
    end

    reader = PDF::Reader.new(pdf)
    reader.pages.each do |page|
      page_number = page.number
      page_text = page.text

      document = {
        id: "#{file_set_id}_#{page_number}",
        file_set_id_ssi: file_set_id,
        has_model_ssim: ["PdfPage"],
        press_tesim: [press],
        page_number_ssi: page_number,
        page_content_tsiv: page_text
      }

      ActiveFedora::SolrService.add(document)
    end

    ActiveFedora::SolrService.commit
  end

  def delete(file_set_id)
    ids = ActiveFedora::SolrService.query("has_model_ssim:PdfPage AND file_set_id_ssi:#{file_set_id}", fl: ['id'], rows: 10_000).map(&:id)
    ids.each do |id|
      ActiveFedora::SolrService.delete(id)
    end
  end

  module_function :add, :delete
end
