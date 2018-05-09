class RapSheetProcessor
  def self.run
    connection = Fog::Storage.new(Rails.configuration.fog_params)
    input_directory = connection.directories.new(key: 'autoclearance-rap-sheet-inputs')
    output_directory = connection.directories.new(key: 'autoclearance-outputs')
    
    input_directory.files.each do |input_file|
      input_file.copy(output_directory.key, input_file.key)
      input_file.destroy
    end
  end
end
