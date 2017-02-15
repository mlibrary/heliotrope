desc "output all fileset titles with reversed sections still present"
require 'csv'
namespace :heliotrope do
  task filesets_with_sections: :environment do
    monograph_titles = [['The Director\'s Prism: E. T. A. Hoffmann and the Russian Theatrical Avant-Garde'],
                        ['Canoes: A Natural History in North America'],
                        ['Animal Acts: Performing Species Today']]
    lines = []
    monograph_titles.each do |mono_title|
      m = Monograph.where(title: mono_title).first
      lines << monograph_metadata(m)
      m.ordered_members.to_a.each do |mm|
        if mm.is_a? Section
          mm.ordered_members.to_a.reverse_each do |sm|
            lines << fileset_metadata(sm)
          end
        else
          # should only be representative fileset, no handle
          lines << fileset_metadata(mm)
        end
      end
    end
    output_filesets_to_csv('filesets_with_sections', lines)
  end
end
