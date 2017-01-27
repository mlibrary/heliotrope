desc "Add sipity entites for existing works that were created prior to CC 1.7.0 workflows(sipity)"
namespace :heliotrope do
  task add_sipity_entities: :environment do

    works = Monograph.all.to_a

    user = User.new(id: 0, user_key: 'system')

    works.each do |work|
      unless Sipity::Entity.find_by(proxy_for_global_id: work.to_global_id.to_s)
        CurationConcerns::Workflow::WorkflowFactory.create(work, {}, user)
        p "Added #{work.to_global_id}"
      end
    end
  end
end
