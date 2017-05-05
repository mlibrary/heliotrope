# frozen_string_literal: true

namespace :staging do
  desc 'Seed the staging database with users'
  task seed: ["staging:unseed", :environment] do
    puts "seeding..."
    # create users and assign roles
    press_count = Press.count
    roles = %w[admin editor user]
    role_count = roles.count
    (1..100).each do |i|
      press = Press.limit(1).offset(rand(press_count)).first
      role = roles[rand(role_count)]
      user = User.create! email: "#{role}.#{press.subdomain}.#{i}@example.com", password: "password", password_confirmation: "password"
      next unless role != "user"
      Role.create! resource_id: press.id, resource_type: "Press", user_id: user.id, role: role
      press2 = Press.limit(1).offset(rand(press_count)).first
      role2 = roles[rand(role_count)]
      next unless role2 != "user"
      next unless press.id != press2.id
      Role.create! resource_id: press2.id, resource_type: "Press", user_id: user.id, role: role2
      press3 = Press.limit(1).offset(rand(press_count)).first
      role3 = roles[rand(role_count)]
      next unless role3 != "user"
      if (press.id != press3.id) && (press2.id != press3.id)
        Role.create! resource_id: press3.id, resource_type: "Press", user_id: user.id, role: role3
      end
    end
    puts "seeded"
  end

  desc 'Unseed the staging database with users'
  task unseed: :environment do
    puts "unseeding..."
    User.all.each do |user|
      user.destroy! if user.email =~ /example.com/
    end
    puts "unseeded"
  end
end
