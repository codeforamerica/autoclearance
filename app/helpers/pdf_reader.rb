class PDFReader
  def initialize(file_contents)
    @file_contents = file_contents
  end

  def text
    reader = PDF::Reader.new(StringIO.new(file_contents))
    reader.pages.map do |page|
      PDFReader.strip_page_header_and_footer(page.text)
    end.join()
  end

  def self.strip_page_header_and_footer page_text
    lines = page_text.split("\n")
    lines.pop while lines.last.blank? || lines.last.lstrip.starts_with?('http://', 'https://', 'file://', 'ﬁle://')
    lines.shift while lines.first.blank? || lines.first.lstrip.starts_with?('Page', 'Route')
    lines.join("\n") + "\n"
  end

  attr_reader :file_contents
end
