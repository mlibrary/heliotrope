# frozen_string_literal: true

module Crossref
  class Metadata
    attr_reader :work, :document

    def initialize(noid)
      @work = Sighrax.hyrax_presenter(Sighrax.factory(noid))
      @document = Nokogiri::XML(File.read(Rails.root.join("config", "crossref", "monograph_metadata_template.xml")))
    end

    def build
      doi_batch_id
      set_timestamp
      book_type
      contributors
      title
      publication_date
      isbns
      publisher_name
      doi
      resource
      document
    end

    def book_type
      document.at_css("book").attribute("book_type").value = if edited_book?
                                                               "edited_book"
                                                             else
                                                               "monograph"
                                                             end
    end

    def contributors
      creators_with_roles = work.creators_with_roles
      document.at_css('contributors') << person_node(creators_with_roles.shift, "first")

      creators_with_roles.each do |creator|
        document.at_css('contributors') << person_node(creator, "additional")
      end
    end

    def person_node(person, seq)
      pn_node = Nokogiri::XML::Node.new('person_name', document)
      pn_node["sequence"] = seq
      pn_node["contributor_role"] = person.role

      given_name_node = Nokogiri::XML::Node.new('given_name', document)
      given_name_node.content = person.firstname
      pn_node << given_name_node

      surname_node = Nokogiri::XML::Node.new('surname', document)
      surname_node.content = person.lastname
      pn_node << surname_node
    end

    def doi_batch_id
      document.at_css('doi_batch_id').content = "#{work.subdomain}-#{work.id}-#{timestamp}"
    end

    def set_timestamp
      document.at_css('timestamp').content = timestamp
    end

    def title
      document.at_css('title').content = work.title
    end

    def publication_date
      year = Nokogiri::XML::Node.new('year', document)
      year.content = work.date_created&.first
      document.at_css('publication_date') << year
    end

    def isbns
      noisbn && return if work.isbn.empty?

      work.isbn.each do |isbn_type|
        isbn, media_type = isbn_media_type(isbn_type)
        next if isbn.blank?

        isbn_node = Nokogiri::XML::Node.new('isbn', document)
        isbn_node['media_type'] = if probably_ebook?(media_type)
                                    "electronic"
                                  else
                                    "print"
                                  end
        isbn_node.content = isbn
        document.at_css('publication_date').add_next_sibling(isbn_node)
      end
    end

    def noisbn
      noisbn = Nokogiri::XML::Node.new('noisbn', document)
      # 'reason' is required if you don't have an isbn (which really should never happen)
      # https://data.crossref.org/reports/help/schema_doc/4.4.0/schema_4_4_0.html#noisbn
      noisbn['reason'] = "monograph"
      document.at_css('publication_date').add_next_sibling(noisbn)
    end

    def isbn_media_type(isbn_type)
      m = isbn_type.match(/\((.*?)\)/)
      media_type = m.present? ? m[1] : ""
      isbn = isbn_type.split(" ")[0] || isbn_type
      [isbn, media_type]
    end

    def probably_ebook?(media_type)
      # "ebook","electronic format","E-Book","E-book","eBook : Adobe Reader","e-book : Adobe Reader","electronic","ebk."
      # also I guess "open access"?
      m = media_type.match(/^ebook|^e-book|^electronic|^open access|^ebk/i)
      return true if m.present?
      false
    end

    def publisher_name
      document.at_css('publisher_name').content = Press.where(subdomain: work.subdomain).first.name
    end

    def doi
      new_doi = "10.3998/#{work.subdomain}.#{work.id}"
      document.at_css('doi').content = work.doi || new_doi
      return if work.doi.present?
      # I guess we should save new DOIs to the monograph...
      m = Monograph.find work.id
      m.doi = new_doi
      m.save
    end

    def resource
      document.at_css('resource').content = work.handle_url
    end

    private

      def timestamp
        Time.current.strftime("%Y%m%d%H%M%S")
      end

      def edited_book?
        # I don't think there's really a good way to determine this.
        # This is what I came up with.
        if work.creator_display?
          return true if work.creator_display =~ /.*?Editor+s$/
        end
        # Does this make sense? Not sure...
        roles = work.creators_with_roles.map(&:role)
        return true if roles.any? { |r| r == "editor" } && roles.none? { |r| r == "author" }

        false
      end
  end
end
