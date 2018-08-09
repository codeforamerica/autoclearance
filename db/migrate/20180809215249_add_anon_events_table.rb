class AddAnonEventsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :anon_events, id: :uuid do |t|
      t.string :agency
      t.string :event_type, null: false
      t.date :date
      t.timestamps
      t.references :anon_rap_sheet, type: :uuid, foreign_key: true, null: false
    end
  end
end
