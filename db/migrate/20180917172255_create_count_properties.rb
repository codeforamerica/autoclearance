class CreateCountProperties < ActiveRecord::Migration[5.2]
  def change
    create_table :count_properties, id: :uuid do |t|
      t.timestamps
      t.references :anon_count, type: :uuid, foreign_key: true, null: false
      t.boolean :has_prop_64_code, null: false
      t.boolean :has_two_prop_64_priors, null: false
      t.string :prop_64_plea_bargain, null: false
    end
  end
end
