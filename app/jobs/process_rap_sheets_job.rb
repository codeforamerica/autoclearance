class ProcessRapSheetsJob < ApplicationJob
  queue_as :default

  def perform(courthouses)
    RapSheetProcessor.new(courthouses).run
  end
end
