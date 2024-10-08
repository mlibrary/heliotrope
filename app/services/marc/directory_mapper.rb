# frozen_string_literal: true

# This stuff has to live somewhere. It could be in a config file maybe, or
# some yaml or whatever, but we need it to map product group_keys to
# locations on ftp.fulcrum.org since they are not always predicatble
module Marc
  class DirectoryMapper
    def self.group_key_cataloging
      {
        "aberdeen" => "/home/fulcrum_ftp/MARC_from_Cataloging/aberdeen",
        "amherst" => "/home/fulcrum_ftp/MARC_from_Cataloging/amherst",
        "bar" => "/home/fulcrum_ftp/MARC_from_Cataloging/BAR",
        "bigten" => "/home/fulcrum_ftp/MARC_from_Cataloging/bigten",
        "bridwell" => "/home/fulcrum_ftp/MARC_from_Cataloging/bridwell",
        "heb" => "/home/fulcrum_ftp/MARC_from_Cataloging/HEB",
        "leverpress" => "/home/fulcrum_ftp/MARC_from_Cataloging/leverpress",
        "michelt" => "/home/fulcrum_ftp/MARC_from_Cataloging/michelt",
        "test_product" => "/home/fulcrum_ftp/heliotropium/cataloging/Testing",
        "umpebc" => "/home/fulcrum_ftp/MARC_from_Cataloging/UMPEBC",
        "vermont" => "/home/fulcrum_ftp/MARC_from_Cataloging/vermont"

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
        "michelt" => "/home/fulcrum_ftp/ftp.fulcrum.org/michelt/KBART",
        "test_product" => "/home/fulcrum_ftp/heliotropium/publishing/Testing/KBART",
        "umpebc" => "/home/fulcrum_ftp/ftp.fulcrum.org/UMPEBC/KBART",
        "vermont" => "/home/fulcrum_ftp/ftp.fulcrum.org/vermont/KBART"
      }
    end
  end
end
