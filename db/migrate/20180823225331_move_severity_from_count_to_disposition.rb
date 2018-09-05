class MoveSeverityFromCountToDisposition < ActiveRecord::Migration[5.2]
  def up
    remove_column :anon_counts, :severity
    add_column :anon_dispositions, :severity, :string
  end

  def down
    add_column :anon_counts, :severity, :string
    remove_column :anon_dispositions, :severity
  end
end
