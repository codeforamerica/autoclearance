class AddCourtCounts < ActiveRecord::Migration[5.2]
  def change
    create_table :court_counts do |t|
      t.string :section
      t.string :code
      t.string :severity
      t.string :code_section_description

      t.timestamps
    end
  end
end
