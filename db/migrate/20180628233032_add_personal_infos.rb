class AddPersonalInfos < ActiveRecord::Migration[5.2]
  def change
    create_table :personal_infos do |t|
      t.string :sex
      
      t.timestamps
    end
  end
end
