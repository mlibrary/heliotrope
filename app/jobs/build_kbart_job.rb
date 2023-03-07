# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

# see HELIO-4408
class BuildKbartJob < ApplicationJob
  def perform
    Greensub::Product.where(needs_kbart: true).each do |product|
      next if product.group_key.nil?

      new_kbart_csv = make_kbart_csv(published_sorted_monographs(product))

      kbart_root_dir = kbart_root(product)

      file_root = if product.group_key == "umpebc"
                    # ebc_2020 product has a kbart file like UMPEBC_2020_2022-08-31.csv
                    "UMP" + product.identifier.upcase
                  else
                    product.identifier
                  end

      # Get the most recent kbart for this product
      old_kbart_csv = most_recent_kbart(kbart_root_dir, file_root)

      # If there's no difference between the most recent and what we have now, do nothing
      next if File.exist?(old_kbart_csv) && (CSV.parse(new_kbart_csv) == CSV.parse(File.read(old_kbart_csv)))

      # Otherwise Write the new kbart file with current YYYY_MM_DD in file name
      # Both the csv
      today = Time.zone.now.strftime "%Y-%m-%d"
      new_kbart_name = kbart_root_dir + "#{file_root}_#{today}"
      File.write(new_kbart_name.to_s + ".csv", new_kbart_csv)

      # And the tsv (but with the .txt extension)
      tabs = CSV.generate(col_sep: "\t", force_quotes: true) do |t|
        CSV.parse(new_kbart_csv).each { |row| t << row }
      end
      File.write(new_kbart_name.to_s + ".txt", tabs)
    end
  end

  def published_sorted_monographs(product)
    monographs = []
    ActiveFedora::SolrService.query("{!terms f=id}#{product.components.map(&:noid).join(',')}", rows: product.components.count).each do |doc|
      next unless doc["visibility_ssi"] == 'open' # only those marked public/published
      monographs << Hyrax::MonographPresenter.new(SolrDocument.new(doc), nil)
    end
    monographs.sort_by { |m| m.page_title }
  end

  def most_recent_kbart(kbart_root_dir, file_root)
    # I guess instead of File.mtime we'll use the actual date in the file name
    # KBART files look like:
    # bar_2022_annual_int_2022-12-16.csv
    # UMPEBC_2016_2023-02-03.csv
    # heb_2022-09-16.csv
    list = {}
    Dir.glob(File.join(kbart_root_dir, "#{file_root}*.csv")).each do |file|
      date = file.match(/(\d\d\d\d-\d\d-\d\d)\.csv$/)[1]
      list[date] = file
    end

    list[list.keys.sort.reverse.first] || ""
  end

  def kbart_root(product)
    if Rails.env.test?
      Rails.root.join("tmp", "spec", "public", "products", product.group_key, "kbart")
    else
      Rails.root.join("public", "products", product.group_key, "kbart")
    end
  end

  def make_kbart_csv(monographs)
    header = %w[
      publication_title
      print_identifier
      online_identifier
      date_first_issue_online
      num_first_vol_online
      num_first_issue_online
      date_last_issue_online
      num_last_vol_online
      num_last_issue_online
      title_url
      first_author
      title_id
      embargo_info
      coverage_depth
      coverage_notes
      publisher_name
    ]

    csv = CSV.generate(force_quotes: true) do |row|
      row << header

      monographs.each do |monograph|
        row << [
          monograph.page_title,
          print_isbn(monograph.isbn),
          online_isbn(monograph.isbn),
          "", # date_first_issue_online
          "", # num_first_vol_online
          "", # num_first_issue_online
          "", # date_last_issue_online
          "", # num_last_vol_online
          "", # num_last_issue_online
          title_url(monograph),
          first_author_last_name(monograph),
          title_id(monograph),
          "", # coverage_depth
          "fulltext",
          publisher_name(monograph)
        ]
      end
    end

    csv
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

    # this is... kind of ugly. It returns the top "priority" isbn if it can find one
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
    # creators are "Lastname, Firstname\nLastname, Firstname"
    monograph.solr_document["creator_tesim"].first.split(",")[0] || ""
  end

  def title_id(monograph)
    # heb needs it's hebid (uppercased)
    if monograph.subdomain == "heb"
      monograph.identifier.each do |identifier|
        match = identifier.match(/^heb_id:(heb\d\d\d\d\d\.\d\d\d\d\.\d\d\d)/)
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
    return "British Archaeological Reports" if monograph.subdomain == "barpublishing"
    # heb gets the monograph's publisher
    return monograph.publisher.first if monograph.subdomain == "heb"
    # the rest get the Press.name (which would be subpress for subpresses)
    monograph.press
  end
end
