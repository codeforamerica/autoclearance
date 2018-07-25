class AddDispositionsToCourtCounts < ActiveRecord::Migration[5.2]
  def change
    add_column :court_counts, :disposition, :string
  end
end
