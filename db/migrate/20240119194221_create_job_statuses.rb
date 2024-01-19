class CreateJobStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :job_statuses do |t|
      t.text :command
      t.string :task
      t.string :noid
      t.boolean :completed, default: false
      t.boolean :error, default: false
      t.text :error_message

      t.timestamps
    end
  end
end
