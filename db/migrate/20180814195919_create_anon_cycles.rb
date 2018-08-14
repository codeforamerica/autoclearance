class CreateAnonCycles < ActiveRecord::Migration[5.2]
  class AnonEvent < ActiveRecord::Base
  end

  class AnonCycle < ActiveRecord::Base
  end

  def up
    create_table :anon_cycles, id: :uuid do |t|
      t.timestamps
      t.references :anon_rap_sheet, type: :uuid, foreign_key: true, null: false
    end

    add_reference :anon_events, :anon_cycle, type: :uuid, foreign_key: true

    AnonEvent.reset_column_information
    AnonCycle.reset_column_information
    AnonEvent.find_each do |event|
      cycle = AnonCycle.create!(anon_rap_sheet_id: event.anon_rap_sheet_id)
      event.anon_cycle_id = cycle.id
      event.save!
    end

    remove_reference :anon_events, :anon_rap_sheet
    change_column_null :anon_events, :anon_cycle_id, false
  end



  def down
    add_reference :anon_events, :anon_rap_sheet, type: :uuid, foreign_key: true

    AnonEvent.reset_column_information
    AnonCycle.reset_column_information
    AnonEvent.find_each do |event|
      cycle = AnonCycle.find(event.anon_cycle_id)
      event.anon_rap_sheet_id = cycle.anon_rap_sheet_id
      event.save!
    end

    remove_reference :anon_events, :anon_cycle
    change_column_null :anon_events, :anon_rap_sheet_id, false
    drop_table :anon_cycles
  end
end
