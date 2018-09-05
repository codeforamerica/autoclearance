class AddCountNumberToAnonCounts < ActiveRecord::Migration[5.2]
  class AnonCount < ApplicationRecord
  end

  def change
    add_column :anon_counts, :count_number, :integer

    AnonCount.reset_column_information
    # rubocop:disable Rails/SkipsModelValidations
    AnonCount.where(count_number: nil).update_all(count_number: 0)
    # rubocop:enable Rails/SkipsModelValidations

    change_column_null(:anon_counts, :count_number, false)
  end
end
