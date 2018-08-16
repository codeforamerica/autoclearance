class AddYearOfBirthToAnonRapSheets < ActiveRecord::Migration[5.2]
  def change
    add_column :anon_rap_sheets, :year_of_birth, :integer
  end
end
