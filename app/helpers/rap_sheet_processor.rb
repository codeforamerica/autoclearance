class RapSheetProcessor
  def self.run
    connection = Fog::Storage.new(Rails.configuration.fog_params)
    directory = connection.directories.new(key: 'autoclearance-rap-sheet-inputs')
    
    puts "Files in directory: #{directory.files.map(&:key)}"
  end
end
