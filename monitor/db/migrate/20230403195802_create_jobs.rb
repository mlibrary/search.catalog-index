class CreateJobs < ActiveRecord::Migration[7.0]
  def change
    create_table :jobs do |t|
      t.string :job_id
      t.string :job_class
      t.string :arguments
      t.string :queue
      t.timestamps
    end
  end
end
