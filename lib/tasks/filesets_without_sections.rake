desc "output all fileset titles with sections removed"
require 'csv'
namespace :heliotrope do
  task filesets_without_sections: :environment do
    monograph_titles = [['The Director\'s Prism: E. T. A. Hoffmann and the Russian Theatrical Avant-Garde'],
                        ['Canoes: A Natural History in North America'],
                        ['Animal Acts: Performing Species Today']]
    lines = []
    monograph_titles.each do |mono_title|
      m = Monograph.where(title: mono_title).first
      lines << monograph_metadata(m)
      m.ordered_members.to_a.each do |mm|
        if mm.is_a? Section
          puts 'SECTION FOUND - WHAT GIVES? PANIC!' + "\n"
        else
          # all filesets should now be here,
          lines << fileset_metadata(mm)
        end
      end
    end
    output_filesets_to_csv('filesets_without_sections', lines)
  end

  def output_filesets_to_csv(prefix, lines)
    if !lines.blank?
      filename = '/tmp/' + prefix + '_' + Time.now.strftime('%Y%m%d%H%M%S') + '.csv'
      CSV.open(filename, 'wb') do |csv|
        lines.each { |line| csv << line }
      end
      puts 'output written to ' + filename
    else
      puts 'no output generated'
    end
  end

  def monograph_metadata(m)
    ['************* MONOGRAPH *************', m.id, m.title.first]
  end

  def fileset_metadata(fs)
    [fs.id, fs.title.first, citable_link(fs)]
  end
  
  # logic found in file_set_presenter.rb
  def citable_link(fileset)
    if fileset.doi.present?
      fileset.doi
    else
      handle_url(fileset)
    end
  end

  def handle_url(fileset)
    if fileset.hdl.present?
      # I guess hdl is multi-valued in the Solr doc, but not here
      "http://hdl.handle.net/2027/fulcrum.#{fileset.hdl}"
    else
      'handle created from id'
    end
  end

end
