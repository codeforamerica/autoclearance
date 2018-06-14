class PDFReader
  def initialize(file_contents)
    @file_contents = file_contents
  end

  def text
    reader = PDF::Reader.new(StringIO.new(file_contents))
    reader.pages.map do |page|
      PDFReader.strip_page_header_and_footer(page.text)
    end.join
  end

  def self.strip_page_header_and_footer(page_text)
    lines = page_text.split("\n")
    lines.pop while lines.any? && (lines.last.strip.empty? || lines.last.lstrip.start_with?('http://', 'https://', 'file://', 'ﬁle://'))
    lines.shift while lines.any? && (lines.first.strip.empty? || lines.first.lstrip.start_with?('Page', 'Route'))
    lines.join("\n") + "\n"
  end

  attr_reader :file_contents
end
