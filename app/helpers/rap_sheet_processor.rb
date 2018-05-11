class RapSheetProcessor
  def self.run
    connection = Fog::Storage.new(Rails.configuration.fog_params)
    input_directory = connection.directories.new(key: Rails.configuration.input_bucket)
    output_directory = connection.directories.new(key: Rails.configuration.output_bucket)
    
    input_directory.files.each do |input_file|
      input_file.copy(output_directory.key, input_file.key)
      input_file.destroy
    end
  end
end
