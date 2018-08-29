namespace :process do
  task la: :environment do
    RapSheetProcessor.new(Counties::LOS_ANGELES).run
  end

  task sf: :environment do
    RapSheetProcessor.new(Counties::SAN_FRANCISCO).run
  end
end
