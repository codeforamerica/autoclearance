namespace :process do
  # abbreviations from http://sv08data.dot.ca.gov/contractcost/map.html
  task la: :environment do
    RapSheetProcessor.new(Counties::LOS_ANGELES).run
  end

  task sf: :environment do
    RapSheetProcessor.new(Counties::SAN_FRANCISCO).run
  end

  task sj: :environment do
    RapSheetProcessor.new(Counties::SAN_JOAQUIN).run
  end

  task cc: :environment do
    RapSheetProcessor.new(Counties::CONTRA_COSTA).run
  end

  task sac: :environment do
    RapSheetProcessor.new(Counties::SACRAMENTO).run
  end
end
