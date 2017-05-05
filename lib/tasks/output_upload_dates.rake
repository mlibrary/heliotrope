# frozen_string_literal: true

desc "print the upload_dates of all file_sets"
# the representative image will be ignored as it's...
# attached directly to the monograph
namespace :heliotrope do
  task output_upload_dates: :environment do
    Monograph.all.each do |m|
      m.ordered_members.to_a.each do |mono_member|
        p mono_member.id + ': ' + mono_member.date_uploaded.to_s
      end
    end
  end
end
