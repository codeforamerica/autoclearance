namespace :rap_sheet do
  desc "This task will strip the identifiable information from a RAP sheet and save the text"
  task deidentify: :environment do
    RapSheetDeidentifier.new.run
  end
end
