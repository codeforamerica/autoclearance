class ProcessRapSheetsJob < ApplicationJob
  queue_as :default

  def perform
    RapSheetProcessor.new.run
  end
end
