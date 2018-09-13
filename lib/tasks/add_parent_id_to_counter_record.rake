# frozen_string_literal: true

desc "Update old counter records to add parent (monograph) id"
namespace :heliotrope do
  task add_parent_id_to_counter_record: :environment do
    CounterReport.where(parent_noid: nil).each do |cr|
      fp = Hyrax::PresenterFactory.build_for(ids: [cr.noid], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
      if fp.present?
        if fp.monograph_id.present?
          cr.parent_noid = fp.monograph_id
          cr.save!
        else
          p "no monograph_id for file_set #{cr.noid}"
        end
      else
        p "no presenter for file_set #{cr.noid}"
      end
    end
  end
end
