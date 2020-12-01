# frozen_string_literal: true

desc "Add the analyst role to all works and file_sets, HELIO-3379"
namespace :heliotrope do
  task add_analyst_role: :environment do
    # This will not work.
    # There's a big story about it in https://tools.lib.umich.edu/jira/browse/HELIO-3613
    # I'll leave this here for now, but we'll need to do HELIO-3613 before
    # we add the analyst role retroactively to all Works/FileSets
    raise "Don't run this, see HELIO-3613"

    Monograph.all.to_a.each do |m|
      analyst = "#{m.press}_analyst"
      next if m.read_groups.include?(analyst)
      p "#{m.id}"
      # If we try to do array operations like "<<" or "push" on m.read_groups
      # it will fail silently because... AF I guess? IDK.
      # It seems you can only assign to m.read_groups with "="
      read_groups = m.read_groups
      read_groups.push(analyst)
      m.read_groups = read_groups
      m.save!
      # This job is being weird... might have to not use it after all...
      InheritPermissionsJob.perform_later(m)
    end
  end
end
