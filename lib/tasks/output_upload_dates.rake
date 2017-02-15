desc "print the upload_dates of all file_sets"
# the representative image will be ignored as it's...
# attached directly to the monograph
namespace :heliotrope do
  task output_upload_dates: :environment do
    Monograph.all.each do |m|
      m.ordered_members.to_a.each do |mono_member|
        # TODO: Remove Sections from this rake task
        if mono_member.is_a? Section
          mono_member.ordered_members.to_a.each do |fs|
            p fs.id + ': ' + fs.date_uploaded.to_s
          end
        else
          p mono_member.id + ': ' + mono_member.date_uploaded.to_s
        end
      end
    end
  end
end
