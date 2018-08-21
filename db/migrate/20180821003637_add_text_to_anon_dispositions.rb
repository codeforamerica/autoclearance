class AddTextToAnonDispositions < ActiveRecord::Migration[5.2]
  def change
    add_column :anon_dispositions, :text, :text
  end
end
