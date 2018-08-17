class AddPersonUniqueIdToAnonRapSheets < ActiveRecord::Migration[5.2]
  def change
    add_column :anon_rap_sheets, :person_unique_id, :binary, limit: 32
  end
end
