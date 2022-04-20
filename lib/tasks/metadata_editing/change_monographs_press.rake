# frozen_string_literal: true

desc 'Take any number of Monograph NOIDs and output CSV to update them'
namespace :heliotrope do
  task change_monographs_press: :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:change_monographs_press[new_press_subdomain, noid1, noid2, noid3,...]"

    noid_chars = ('a'..'z').to_a + ('0'..'9').to_a
    monographs = []

    new_subdomain = nil
    noids = []

    fail "You must provide a subdomain value and at least one Monograph NOID" unless args.extras.count > 1

    args.extras.each_with_index do |arg, index|
      # the first argument is the new subdomain ("press") value for the Monographs
      if index.zero?
        new_subdomain = arg
        unless Press.exists?(subdomain: new_subdomain)
          fail "No press found with subdomain: '#{new_subdomain}'"
        end
      else
        noids << arg
      end
    end

    noids.each do |noid|
      if noid.length != 9 || !noid.chars.all? { |ch| noid_chars.include?(ch) }
        puts "Invalid NOID detected: #{noid} .................. SKIPPING"
        return
      end

      matches = Monograph.where(id: noid)
      if matches.count.zero?
        puts "No Monograph found with NOID #{noid} ............ EXITING"
        return
      elsif matches.count > 1
        puts "More than 1 Monograph found with NOID #{noid} ... EXITING" # impossible
        return
      else
        monographs << matches.first
      end
    end

    monographs.each do |monograph|
      puts "Moving Monograph #{monograph.id} (\"#{monograph.title.first}\") to Press \"#{new_subdomain}\" and setting correct permissions..."

      monograph.press = new_subdomain
      # because a Monograph originally created in the UI may have a depositor with no role in the new press, we'll...
      # change depositor to the batch user, but leave read_users and edit_users as they are. Those are rarely used...
      # apart from occasionally adding an author or an editor's email to a Monograph for pre-publication review.
      monograph.depositor = User.batch_user_key

      new_subdomain_admin_role = "#{new_subdomain}_admin"
      new_subdomain_editor_role = "#{new_subdomain}_editor"
      new_subdomain_analyst_role = "#{new_subdomain}_analyst"

      # removing 'public' from read_groups using `read_groups=` *immediately* sets visibility to 'restricted' on the...
      # object, which is why we'll be explicit with the wrapping conditional here. Can't check visibility afterwards!
      if monograph.visibility == 'open'
        monograph.read_groups = ['public', new_subdomain_admin_role, new_subdomain_editor_role, new_subdomain_analyst_role]
      else
        # i.e. don't "publish" the Monograph just cause it's changing Press
        monograph.read_groups = [new_subdomain_admin_role, new_subdomain_editor_role, new_subdomain_analyst_role]
      end

      monograph.edit_groups = [new_subdomain_admin_role, new_subdomain_editor_role]
      monograph.save!

      FileSet.where(monograph_id_ssim: monograph.id).each do |file_set|
        puts "Setting permissions on child FileSet #{file_set.id}..."

        # FileSet permission changes follow the same rationale as for the parent Monograph per the comment above.
        # However beforehand, to clear away any existing problems we'll zap all groups, save and reload, which...
        # necessitates storing (or using) the initial visibility first.
        if file_set.visibility == 'open'
          new_read_groups = ['public', new_subdomain_admin_role, new_subdomain_editor_role, new_subdomain_analyst_role]
        else
          new_read_groups = [new_subdomain_admin_role, new_subdomain_editor_role, new_subdomain_analyst_role]
        end

        file_set.read_groups = []
        file_set.edit_groups = []
        file_set.save!
        file_set.reload

        file_set.read_groups = new_read_groups
        file_set.edit_groups = [new_subdomain_admin_role, new_subdomain_editor_role]
        file_set.save!
      end
    end

    puts "Done."
  end
end
