desc "reverse the upload_dates of all file_sets"
# the representative image will be ignored as it's...
# attached directly to the monograph
namespace :heliotrope do
  task reverse_upload_dates: :environment do
    Monograph.all.each do |m|
      fileset_dates = []
      m.ordered_members.to_a.each do |mono_member|
        if mono_member.is_a? Section
          mono_member.ordered_members.to_a.each do |fs|
            fileset_dates << fs.date_uploaded
          end
        end
      end
      fileset_dates.sort!
      i=0
      m.ordered_members.to_a.each do |mono_member|
        if mono_member.is_a? Section
          mono_member.ordered_members.to_a.reverse_each do |fs|
            fs.date_uploaded = fileset_dates[i]
            fs.save!
            i+=1
          end
        end
      end
    end
  end
end
