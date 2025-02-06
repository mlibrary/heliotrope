# frozen_string_literal: true

# This stuff has to live somewhere. It could be in a config file maybe, or
# some yaml or whatever, but we need it to map product group_keys to
# locations on ftp.fulcrum.org since they are not always predicatble
module Marc
  class DirectoryMapper
    # HELIO-4760
    # "press_cataloging" is TEMPORARY :)
    # For now we can map Press to cataloging location bypassing the need for Product.group_key to exist
    # That way we can correctly categorize MARC records before they have a Product or Component (when they're still Draft)
    def self.press_group_key
      {
        "aberdeen" => "aberdeen",
        "amherst" => "amherst",
        "bar" => "bar",
        "bigten" => "bigten",
        "bridwell" => "bridwell",
        "heb" => "heb",
        "leverpress" => "leverpress",
        "livedplaces" => "livedplaces",
        "michelt" => "michelt",
        "test_product" => "test_product",
        "michigan" => "umpebc",
        "vermont" => "vermont",
        "westminster" => "westminster"
      }
    end

    def self.group_key_cataloging
      {
        "aberdeen" => "/home/fulcrum_ftp/MARC_from_Cataloging/aberdeen",
        "amherst" => "/home/fulcrum_ftp/MARC_from_Cataloging/amherst",
        "bar" => "/home/fulcrum_ftp/MARC_from_Cataloging/BAR",
        "bigten" => "/home/fulcrum_ftp/MARC_from_Cataloging/bigten",
        "bridwell" => "/home/fulcrum_ftp/MARC_from_Cataloging/bridwell",
        "heb" => "/home/fulcrum_ftp/MARC_from_Cataloging/HEB",
        "leverpress" => "/home/fulcrum_ftp/MARC_from_Cataloging/leverpress",
        "livedplaces" => "/home/fulcrum_ftp/MARC_from_Cataloging/livedplaces",
        "michelt" => "/home/fulcrum_ftp/MARC_from_Cataloging/michelt",
        "test_product" => "/home/fulcrum_ftp/heliotropium/cataloging/Testing",
        "umpebc" => "/home/fulcrum_ftp/MARC_from_Cataloging/UMPEBC",
        "vermont" => "/home/fulcrum_ftp/MARC_from_Cataloging/vermont",
        "westminster" => "/home/fulcrum_ftp/MARC_from_Cataloging/westminster"
      }
    end

    def self.group_key_kbart
      {
        "aberdeen" => "/home/fulcrum_ftp/ftp.fulcrum.org/aberdeen/KBART",
        "amherst" => "/home/fulcrum_ftp/ftp.fulcrum.org/Amherst_College_Press/KBART",
        "bar" => "/home/fulcrum_ftp/ftp.fulcrum.org/BAR/KBART",
        "bigten" => "/home/fulcrum_ftp/ftp.fulcrum.org/bigten/KBART",
        "bridwell" => "/home/fulcrum_ftp/ftp.fulcrum.org/bridwell/KBART",
        "heb" => "/home/fulcrum_ftp/ftp.fulcrum.org/HEB/KBART",
        "leverpress" => "/home/fulcrum_ftp/ftp.fulcrum.org/Lever_Press/KBART",
        "livedplaces" => "/home/fulcrum_ftp/ftp.fulcrum.org/livedplaces/KBART",
        "michelt" => "/home/fulcrum_ftp/ftp.fulcrum.org/michelt/KBART",
        "test_product" => "/home/fulcrum_ftp/heliotropium/publishing/Testing/KBART",
        "umpebc" => "/home/fulcrum_ftp/ftp.fulcrum.org/UMPEBC/KBART",
        "vermont" => "/home/fulcrum_ftp/ftp.fulcrum.org/vermont/KBART",
        "westminster" => "/home/fulcrum_ftp/ftp.fulcrum.org/westminster/KBART"
      }
    end
  end
end
