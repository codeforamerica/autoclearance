class AddSexToAnonRapSheet < ActiveRecord::Migration[5.2]
  def change
    add_column :anon_rap_sheets, :sex, :string
  end
end
