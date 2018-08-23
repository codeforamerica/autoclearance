class MoveSeverityFromCountToDisposition < ActiveRecord::Migration[5.2]
  def change
    remove_column :anon_counts, :severity
    add_column :anon_dispositions, :severity, :string
  end
end
