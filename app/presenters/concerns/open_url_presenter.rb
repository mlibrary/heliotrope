module OpenUrlPresenter
  extend ActiveSupport::Concern

  # COinS for Zotero, etc
  # See #138, #679

  def file_set_coins_title
    fields = []
    fields << "ctx_ver=Z39.88-2004"
    fields << "rft_val_fmt=info:ofi/fmt:kev:mtx:dc"
    fields << "rfr_id=info:sid/fulcrum.org"
    fields << "rft.genre=bookitem"
    fields << "rft.source=fulcrum.org"
    fields << "rft.identifier=#{CGI.escape(citable_link)}"
    fields << "rft.au=#{CGI.escape(creator_full_name.first)}" if creator_full_name.present?

    contributor.each do |contrib|
      fields << "rft.au=#{CGI.escape(contrib)}"
    end

    fields << "rft.title=#{CGI.escape(page_title)}" if page_title.present?
    fields << "rft.description=#{CGI.escape(MarkdownService.markdown_as_text(description.first))}" if description.present?

    subjects.each do |subject|
      fields << "rft.subject=#{CGI.escape(subject)}"
    end

    fields << "rft.date=#{CGI.escape(sort_date.first[0, 4])}" if sort_date.present?
    fields.join('&')
  end

  def monograph_coins_title
    fields = []
    fields << "ctx_ver=Z39.88-2004"
    fields << "rft_val_fmt=info:ofi/fmt:kev:mtx:book"
    fields << "rfr_id=info:sid/fulcrum.org"
    fields << "rft.source=fulcrum.org"
    fields << "rft.au=#{CGI.escape(creator_full_name.first)}" if creator_full_name.present?

    contributor.each do |contrib|
      fields << "rtf.au=#{CGI.escape(contrib)}"
    end

    fields << "rft.title=#{CGI.escape(page_title)}" if page_title.present?
    fields << "rft.description=#{CGI.escape(MarkdownService.markdown_as_text(description.first))}" if description.present?

    subject.each do |subj|
      fields << "rft.subject=#{CGI.escape(subj)}"
    end

    fields << "rft.date=#{CGI.escape(date_published.first)}" if date_published.present?
    fields << "rft.isbn=#{CGI.escape(isbn.first)}" if isbn.present?

    publisher.each do |pub|
      fields << "rft.publisher=#{CGI.escape(pub)}"
    end

    fields.join('&')
  end
end
