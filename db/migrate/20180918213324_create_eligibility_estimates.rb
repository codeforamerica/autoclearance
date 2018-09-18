class CreateEligibilityEstimates < ActiveRecord::Migration[5.2]
  def change
    create_table :eligibility_estimates, id: :uuid do |t|
      t.timestamps
      t.references :count_properties, type: :uuid, foreign_key: true, null: false
      t.string :prop_64_eligible, null: false
    end
  end
end
