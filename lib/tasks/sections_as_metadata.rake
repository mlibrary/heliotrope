namespace :heliotrope do

  desc "move filesets to monograph, sections to fileset metadata"
  task sections_as_metadata: :environment do

    puts "\nObject counts"
    puts "  Monograph: #{Monograph.count}"
    puts "  Section: #{Section.count}"
    puts "  FileSet: #{FileSet.count}"

    Monograph.all.each do |mono|
      puts "\nMigrating data for monograph: #{mono.title.to_a}"

      new_mono_members = []
      mono.ordered_members.to_a.each do |mono_member|
        title = mono_member.title.to_a

        case mono_member
        when Section
          puts "  Migrating data for section: #{title}"

          # 1) We are assuming they are all FileSets
          # 2) FileSets are in reverse order within each Section, undoing...
          # that as we move them to the monograph
          mono_member.ordered_members.to_a.reverse_each do |fs|
            puts "    Migrating data for file: #{fs.title.to_a}"
            fs.section_title += title
            fs.save!
            new_mono_members << fs
          end

          mono_member.ordered_members = []
          mono_member.members = []
          mono_member.save!
        when FileSet
          puts "  Existing fileset: #{title}"
          new_mono_members << mono_member
        else
          # Should never get here.
        end
      end

      mono.ordered_members = new_mono_members
      mono.save!
    end

    puts "\nDeleting all Section records"
    Section.destroy_all

    puts "\nUpdating all FileSet indexes"
    # We need to reindex the file_sets so they know their parent's (now a monograph) id
    Monograph.all.each do |m|
      m.ordered_members.to_a.each do |f|
        f.update_index
      end
    end

    puts "\nObject counts"
    puts "  Monograph: #{Monograph.count}"
    puts "  Section: #{Section.count}"
    puts "  FileSet: #{FileSet.count}"

    puts "\nMigration complete."
  end
end
