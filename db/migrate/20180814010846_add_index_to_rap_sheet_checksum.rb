class AddIndexToRapSheetChecksum < ActiveRecord::Migration[5.2]
  def change
    add_index :anon_rap_sheets, :checksum, :unique => true
  end
end
