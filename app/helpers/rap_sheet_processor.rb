class RapSheetProcessor
  def self.run
    connection = Fog::Storage.new(Rails.configuration.fog_params)
    input_directory = connection.directories.new(key: Rails.configuration.input_bucket)
    output_directory = connection.directories.new(key: Rails.configuration.output_bucket)

    input_directory.files.each do |input_file|
      reader = PDF::Reader.new(StringIO.new(input_file.body))

      output_directory.files.create(
        key: input_file.key.gsub('.pdf', '.txt'),
        body: self.get_pdf_text(reader)
      )
      input_file.destroy
    end
  end

  def self.get_pdf_text reader
    reader.pages.map do |page|
      self.strip_page_header_and_footer(page.text)
    end.join()
  end

  def self.strip_page_header_and_footer page_text
      lines = page_text.split("\n")
      lines.pop while lines.last.blank? || lines.last.lstrip.starts_with?('http://', 'https://', 'file://', 'ﬁle://')
      lines.shift while lines.first.blank? || lines.first.lstrip.starts_with?('Page', 'Route')
      lines.join("\n") + "\n"
  end
end
