class CreateEventProperties < ActiveRecord::Migration[5.2]
  def change
    create_table :event_properties, id: :uuid do |t|
      t.timestamps
      t.references :anon_event, type: :uuid, foreign_key: true, null: false
      t.boolean :has_felonies, null: false
      t.boolean :has_probation, null: false
      t.boolean :has_probation_violations, null: false
      t.boolean :has_prison, null: false
      t.boolean :dismissed_by_pc1203, null: false
    end
  end
end
