namespace :process do
  task la: :environment do
    RapSheetProcessor.new(Courthouses::LOS_ANGELES).run
  end
  
  task sf: :environment do
    RapSheetProcessor.new(Courthouses::SAN_FRANCISCO).run
  end
end
