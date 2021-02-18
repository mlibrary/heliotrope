# frozen_string_literal: true

class PdfsController < CheckpointController
  include Watermark::Watermarkable

  def show
    id = params[:id] # file_set ID
    pdf = Sighrax.from_noid(id) # Sighrax::PortableDocumentFormat
    # pdf.parent # Monograph; goes to solr based on monograph_id_ssim

    policy = PdfPolicy.new(current_actor, pdf)
    policy.authorize! :show?

    do_download
  end
end

