# frozen_string_literal: true
require 'json'

desc 'Find high traffic and allocation requests in the rails log'
namespace :heliotrope do
  task high_traffic_report: :environment do
    Line = Struct.new(:id, :ip, :time, :path, :allocations)
    lines = []
    ips = {}

    # This matches the current (2024) semantic_logger format.
    # It's very fragile.
    # We're currently using format = :color for semantic logger so the request time comes though bolded and looks like
    # \e[1m298.1ms\e[0m
    # where the actual time is 298.1 milliseconds so this is pretty gnarly.
    # All could possibly be avoided if we switched to config.rails_semantic_logger.format = :json
    regex = %r{
      ^.*
      (?<id>\w{8}-\w{4}-\w{4}-\w{4}-\w{12})   # the request id
      .*
      ip:\s(?<ip>\d+\.\d+.\d+.\d+)            # the request ip address
      .*
      \(                                      # open parenthesis for the time
      \e\[1m                                  # begining of bold due to semantic logger color formatting
      (?<time>.*)                             # time in seconds or milliseconds
      \e\[0m                                  # close bold
      \)                                      # end parens
      .*
      :path=>"(?<path>...*)"                  # path
      .*
      :allocations=>(?<allocations>\d*)       # number of allocations
      .*$
    }x

    log_file = Rails.env.development? ? "development.log" : "production.log"

    puts "Reading #{log_file}...\n"

    IO.readlines(Rails.root.join("log", log_file)).each do |line|
      regex.match(line) do |m|
        lines << Line.new(m[:id], m[:ip], m[:time], m[:path], m[:allocations].to_i)
        ips[m[:ip]].present? ? ips[m[:ip]] += 1 : ips[m[:ip]] = 1
      end
    end

    puts "\n\n"
    puts "#" * 80
    puts "# Top 10 Highest Traffic IP Addresses Today"
    puts "# Count\tIP"
    puts "#" * 80
    ips.sort_by { |_k, v| v }.reverse[0..9].each do |ip, count|
      puts "#{count}\t#{ip}"
    end

    puts "\n\n"
    puts "#" * 80
    puts "# Top 50 Highest Allocations Requests Today"
    puts "# Allocations\tID\tTime\tIP\tPath"
    puts "#" * 80

    lines.sort_by { |l| -l.allocations }[0..49].each do |line|
      puts "#{line.allocations}\t#{line.id}\t#{line.time}\t#{line.ip}\t#{line.path}"
    end
  end
end
