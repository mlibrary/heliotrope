# frozen_string_literal: true

require 'csv'

desc 'creator mapping'
namespace :heliotrope do
  task creator_mapping: :environment do
    puts "\"NOID\",\"Type\",\"*new* creator\",\"*new* contributor\",\"creator_given_name\",\"creator_family_name\",\"primary_creator_role\",\"contributor.join(', ')\",\"primary_editor_family_name\",\"primary_editor_given_name\",\"m.editor.join(', ')\""

    Monograph.all.to_a.each do |m|
      # all contributors for monographs will be tacked on to creator
      monograph_creator = monograph_combined_creator(m)

      csv_string = CSV.generate do |csv|
        csv << [m.id, 'Monograph', monograph_creator, '', m.creator_given_name, m.creator_family_name, 'N/A', m.contributor.join(', '), m.primary_editor_family_name, m.primary_editor_given_name, m.editor.join(', ')]
      end
      puts csv_string

      # m.creator = Array.wrap(monograph_creator)
      # m.contributor = []
      # m.save!
    end

    FileSet.all.to_a.each do |f|
      file_set_creator = file_set_combined_creator(f)

      csv_string = CSV.generate do |csv|
        csv << [f.id, 'FileSet', file_set_creator, f.contributor.join("\n"), f.creator_given_name, f.creator_family_name, f.primary_creator_role.join(', '), f.contributor.join(', '), 'N/A', 'N/A', 'N/A']
      end
      puts csv_string

      # f.creator = Array.wrap(file_set_creator)
      # f.contributor = Array.wrap(f.contributor.join("\n"))
      # f.save!
    end
  end
end

def monograph_combined_creator(m) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  creator = m.creator_family_name || ''
  creator += ', ' + m.creator_given_name if m.creator_given_name.present?

  m.contributor.each do |c|
    creator += "\n" + c
  end

  editor = m.primary_editor_family_name || ''
  editor += ', ' + m.primary_editor_given_name if m.primary_editor_given_name.present?
  editor += ' (editor)' if editor.present?

  m.editor.each do |e|
    editor += "\n" + e + ' (editor)'
  end

  if creator.present?
    if editor.present?
      creator + "\n" + editor
    else
      creator
    end
  elsif editor.present?
    editor
  else
    ''
  end
end

def file_set_combined_creator(f)
  creator = f.creator_family_name || ''
  creator += ', ' + f.creator_given_name if f.creator_given_name.present?
  creator += ' (' + f.primary_creator_role.join(', ') + ')' if f.primary_creator_role.present?
  creator
end
