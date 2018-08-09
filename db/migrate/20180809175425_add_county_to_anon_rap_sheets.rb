class AddCountyToAnonRapSheets < ActiveRecord::Migration[5.2]
  def change
    add_column :anon_rap_sheets, :county, :string, null: false
  end
end
