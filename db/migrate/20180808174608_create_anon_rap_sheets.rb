class CreateAnonRapSheets < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'pgcrypto'
    create_table :anon_rap_sheets, id: :uuid do |t|
      t.binary :checksum, null: false, limit: 32
      t.timestamps
    end
  end
end
