class CreateRapSheetProperties < ActiveRecord::Migration[5.2]
  def change
    create_table :rap_sheet_properties, id: :uuid do |t|
      t.timestamps
      t.references :anon_rap_sheet, type: :uuid, foreign_key: true, null: false
      t.boolean :has_superstrikes, null: false
      t.boolean :has_sex_offender_registration, null: false
      t.boolean :deceased, null: false
    end
  end
end
