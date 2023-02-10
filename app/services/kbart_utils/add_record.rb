# frozen_string_literal: true

module KbartUtils
  module AddRecord
    # see HELIO-4408

    class << self
      # This is called as an after_save hook from the Monograph model.
      # So each time a monograph is saved, the Kbart row will either be
      # created, updated or at the least have it's updated_at field changed.
      # We'll use the updated_at to determine if a new kbart file should be
      # created for a product.
      def create_or_update(monograph)
        Kbart.where(noid: monograph.id).first_or_initialize.tap do |kbart|
          kbart.publication_title = MarkdownService.markdown_as_text(monograph.title.first)
          kbart.print_identifier  = print_isbn(monograph.isbn)
          kbart.online_identifier = online_isbn(monograph.isbn)
          kbart.title_url         = title_url(monograph)
          kbart.first_author      = first_author_last_name(monograph)
          kbart.title_id          = title_id(monograph)
          kbart.coverage_depth    = "fulltext"
          kbart.publisher_name    = publisher_name(monograph)

          kbart.touch :updated_at if kbart.persisted? # rubocop:disable Rails::SkipsModelValidations

          kbart.save
        end
      end

      def print_isbn(isbns)
        priority_list = {
          "hardcover" => 1,
          "cloth" => 2,
          "Hardcover" => 3,
          "print" => 4,
          "hardcover : alk. paper" => 5,
          "hc. : alk. paper" => 6,
          "paperback" => 7,
          "paper" => 8,
          "Paper" => 9,
          "pb." => 10,
          "pb. : alk. paper" => 11,
          "paper with cd" => 12,
          "paper plus cd rom" => 13
        }

        priority_isbn(isbns, priority_list)
      end

      def online_isbn(isbns)
        # Prefer OA ISBNs over other kinds
        priority_list = {
          "open access" => 1,
          "open-access" => 2,
          "OA" => 3,
          "ebook" => 4,
          "e-book" => 5,
          "ebook epub" => 6,
          "PDF" => 7,
          "ebook pdf" => 8,
          "pdf" => 9
        }

        priority_isbn(isbns, priority_list)
      end

      def priority_isbn(isbns, priority_list)
        results = {}
        isbns.each do |isbn|
          # normal entries look like:
          # ["978-0-472-07581-2 (hardcover)", "978-0-472-05581-4 (paper)", "978-0-472-90313-9 (open access)"]
          matches = isbn.match(/^(.*) \((.*)\)/)
          # There are some isbns (like 15 maybe) that don't have a (type) and look like:
          # "9780262512503", "9780262730068", "9780262230032"
          # And we know that some heb monographs don't have an ISBN at all. If there's no type, just return nothing,
          # as we would do for books that have no ISBN. Seems like it's better to return nothing than the wrong thing.
          if matches.present?
            isbn_numbers = matches[1].delete("-")
            type = matches[2]
            results[priority_list[type]] = isbn_numbers
          end
        end

        # this is... kind of ugly, sorry
        results.delete(nil)
        return "" if results.empty?

        results.sort_by { |k, v| k }&.first[1] || ""
      end

      def title_url(monograph)
        # prefer DOI, otherwise return the handle
        return "https://doi.org/" + monograph.doi if monograph.doi.present?

        # We've got some values in hdl like "2027/spo.13469761.0014.001" so some none-fulcrum handles
        # I guess prefer whatever is in hdl
        return "https://hdl.handle.net/" + monograph.hdl if monograph.hdl.present?
        # Otherwise use the generic fulcrum handle that everything is supposed to get
        "https://hdl.handle.net/" + HandleNet::FULCRUM_HANDLE_PREFIX + monograph.id
      end

      def first_author_last_name(monograph)
        # creators are Lastname, Firstname\nLastname Firstname
        monograph.creator.first.split(",")[0] || ""
      end

      def title_id(monograph)
        # heb needs it's hebid (uppercased)
        if monograph.press == "heb"
          monograph.identifier.each do |identifier|
            match = identifier.match(/heb_id:(.*)/)
            next if match.nil?
            return match[1].upcase if match[1].present?
          end
        end

        # doi
        return monograph.doi if monograph.doi.present?

        # handle
        # As with title_url, use what's in hdl if it exists
        return monograph.hdl if monograph.hdl.present?

        HandleNet::FULCRUM_HANDLE_PREFIX + monograph.id
      end

      def publisher_name(monograph)
        # bar always gets this
        return "British Archaeological Reports" if monograph.press == "bar"
        # heb gets the monograph's publisher
        return monograph.publisher.first if monograph.press == "heb"
        # the rest get the Press.name (which would be subpress for subpresses)
        Press.where(subdomain: monograph.press).first&.name
      end
    end
  end
end
