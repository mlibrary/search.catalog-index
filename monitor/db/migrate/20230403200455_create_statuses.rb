class CreateStatuses < ActiveRecord::Migration[7.0]
  def change
    create_table :statuses do |t|
      t.integer :name
      t.references :job, foreign_key: true
      t.timestamps
    end
  end
end
