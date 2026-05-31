# frozen_string_literal: true

require "set"

module BagIt
  module Info
    @@bag_info_headers = {
      agent: "Bag-Software-Agent",
      org: "Source-Organization",
      org_addr: "Organization-Address",
      contact_name: "Contact-Name",
      contact_phone: "Contact-Phone",
      contact_email: "Contact-Email",
      ext_desc: "External-Description",
      ext_id: "External-Identifier",
      size: "Bag-Size",
      group_id: "Bag-Group-Identifier",
      group_count: "Bag-Count",
      sender_id: "Internal-Sender-Identifier",
      int_desc: "Internal-Sender-Description",
      date: "Bagging-Date",
      oxum: "Payload-Oxum"
    }

    def bag_info_txt_file
      File.join bag_dir, "bag-info.txt"
    end

    def bag_info
      read_info_file bag_info_txt_file
    rescue
      {}
    end

    def write_bag_info(hash = {})
      hash = bag_info.merge(hash)
      hash[@@bag_info_headers[:agent]] = "BagIt Ruby Gem (https://github.com/tipr/bagit)" if hash[@@bag_info_headers[:agent]].nil?
      hash[@@bag_info_headers[:date]] = Date.today.strftime("%Y-%m-%d") if hash[@@bag_info_headers[:date]].nil?
      hash[@@bag_info_headers[:oxum]] = payload_oxum
      write_info_file bag_info_txt_file, hash
    end

    def bagit_txt_file
      File.join bag_dir, "bagit.txt"
    end

    def bagit
      read_info_file bagit_txt_file
    end

    def write_bagit(hash)
      write_info_file bagit_txt_file, hash
    end

    def update_bag_date
      hash["Bagging-Date"] = Date.today.strftime("%Y-%m-%d")
      write_bag_info(hash)
    end

    protected

    def read_info_file(file)
      File.open(file) do |io|
        entries = io.read.split(/\n(?=[^\s])/)

        entries.inject({}) do |hash, line|
          name, value = line.chomp.split(/\s*:\s*/, 2)
          hash.merge(name => value)
        end
      end
    end

    def write_info_file(file, hash)
      dups = hash.keys.inject(Set.new) { |acc, key|
        a = hash.keys.grep(/#{key}/i)
        acc + (a.size > 1 ? a : [])
      }

      raise "Multiple labels (#{dups.to_a.join ", "}) in #{file}" unless dups.empty?

      File.open(file, "w") do |io|
        hash.each do |name, value|
          simple_entry = "#{name}: #{value.gsub(/\s+/, " ")}"

          entry = if simple_entry.length > 79
            simple_entry.wrap(77).indent(2)
          else
            simple_entry
          end

          io.puts entry
        end
      end
    end
  end
end
