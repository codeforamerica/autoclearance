class CreateAnonDispositions < ActiveRecord::Migration[5.2]
  def change
    create_table :anon_dispositions, id: :uuid do |t|
      t.timestamps
      t.references :anon_count, type: :uuid, foreign_key: true, null: false
      t.string :disposition_type, null: false
      t.string :sentence
    end
  end
end
