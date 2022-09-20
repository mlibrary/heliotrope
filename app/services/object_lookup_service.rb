# frozen_string_literal: true

# A service to find an object from a provided ID or CSV row
class ObjectLookupService
  def self.matches_for_csv_row(row)
    if row['NOID']
      [ActiveFedora::Base.where(id: row['NOID']), 'NOID']
    elsif row['Identifier(s)'] && row['Press'] == 'heb'
      # Identifier(s) is a multi-valued field with entries separated by a ';'
      heb_ids = HebHandleService.heb_ids_from_identifier(row['Identifier(s)'].split(';'))
      [ActiveFedora::Base.where(press_sim: 'heb', identifier_ssim: heb_ids), "HEB IDs #{heb_ids.join(', ')}"]
    elsif row['ISBN(s)']
      # ISBN(s) is a multi-valued field with entries separated by a ';'
      clean_isbns = clean_isbns(row['ISBN(s)'])
      # ISBNs do not necessarily uniquely identify a Monograph across all of Fulcrum, but should within a given Press
      if row['Press']
        [ActiveFedora::Base.where(press_sim: row['Press'], isbn_numeric: clean_isbns), "ISBN(s) #{clean_isbns.join(', ')}, restricted to Press '#{row['Press']}'"]
      else
        # within a TMM CSV context this branch shouldn't happen
        [ActiveFedora::Base.where(isbn_numeric: clean_isbns), "ISBN(s) #{clean_isbns.join(', ')}"]
      end
    else
      [[], 'no suitable identifier found']
    end
  end

  # This is just a simpler version of find_using_csv_row() where the type of the `id` param is "detected" automatically.
  def self.matches(id, press = nil)
    if /^[[:alnum:]]{9}$/.match?(id)
      ActiveFedora::Base.where(id: id)
    elsif /^heb[0-9]{5}.[0-9]{4}.[0-9]{3}$/.match?(id) # HEB ID, unlike above we assume press on this conditional
      # Identifier(s) is a multi-valued field with entries separated by a ';'
      # heb_ids = HebHandleService.heb_ids_from_identifier(row['Identifier(s)'].split(';'))
      ActiveFedora::Base.where(press_sim: 'heb', identifier_ssim: id)
    elsif [10, 13].include? id.delete("^0-9").length # ISBN has 10 or 13 digits
      cleaned_isbn = clean_isbns(id).first

      # ISBNs do not necessarily uniquely identify a Monograph across all of Fulcrum, but should within a given Press
      if press
        ActiveFedora::Base.where(press_sim: press, isbn_numeric: cleaned_isbn)
      else
        ActiveFedora::Base.where(isbn_numeric: cleaned_isbn)
      end
    else
      []
    end
  end

  def self.clean_isbns(isbns)
    clean_isbns = []
    isbns&.split(';')&.map(&:strip)&.each do |isbn|
      isbn = isbn.delete('-').downcase
      clean_isbns << isbn.sub(/\s*\(.+\)$/, '').delete('^0-9').strip
    end
    clean_isbns.reject(&:blank?)
  end
end
