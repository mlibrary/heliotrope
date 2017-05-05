# frozen_string_literal: true

namespace :press do
  desc 'Print info about all the presses'
  task list: :environment do
    puts "Presses:"
    puts "Subdomain : Name"
    puts ""

    Press.all.each do |press|
      puts "#{press.subdomain} : #{press.name}"
    end
  end
end
