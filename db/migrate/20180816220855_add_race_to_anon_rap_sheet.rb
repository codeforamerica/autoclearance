class AddRaceToAnonRapSheet < ActiveRecord::Migration[5.2]
  def change
    add_column :anon_rap_sheets, :race, :string
  end
end
