# frozen_string_literal: true

desc 'Take any number of user emails and delete the users, cleaning up metadata'
namespace :heliotrope do
  task delete_users: :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:delete_users[email1, email2, email3,...]"

    args.extras.each do |arg|
      user = User.find_by(email: arg)
      if user
        puts "Deleting user #{arg}"
        user.destroy # also removed associate roles thanks to `dependent: :destroy`
      else
        puts "User #{arg} not found. Metadata checks will proceed."
      end

      # this is also stored in `depositor_tesim` but let's assume there's no way they're out of alignment
      docs = ActiveFedora::SolrService.query("+depositor_ssim:#{arg}", rows: 100_000)
      if docs.count > 0
        puts "#{docs.count} objects have #{arg} as depositor. setting to batch/system user."
        docs.each do |doc|
          item = ActiveFedora::Base.find(doc.id)
          item.depositor = User.batch_user_key
          item.save!
        end
      else
        puts "No objects have #{arg} as depositor."
      end

      docs = ActiveFedora::SolrService.query("+read_access_person_ssim:#{arg}", rows: 100_000)
      if docs.count > 0
        puts "#{docs.count} objects have #{arg} in read_users. Removing."
        docs.each do |doc|
          item = ActiveFedora::Base.find(doc.id)
          item.read_users -= [arg]
          item.save!
        end
      else
        puts "No objects have #{arg} in read_users."
      end

      docs = ActiveFedora::SolrService.query("+edit_access_person_ssim:#{arg}", rows: 100_000)
      if docs.count > 0
        puts "#{docs.count} objects have #{arg} in edit_users. Removing."
        docs.each do |doc|
          item = ActiveFedora::Base.find(doc.id)
          item.edit_users -= [arg]
          item.save!
        end
      else
        puts "No objects have #{arg} in edit_users."
      end
      puts
    end

    puts 'Deletion complete.'
  end
end
