class AddAnonCountsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :anon_counts, id: :uuid do |t|
      t.string :code
      t.string :section
      t.string :description
      t.string :severity
      t.timestamps
      t.references :anon_event, type: :uuid, foreign_key: true, null: false
    end
  end
end
