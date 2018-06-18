class ProcessRapSheetsJob < ApplicationJob
  queue_as :default

  def perform
    RapSheetProcessor.run
  end
end
