require 'rails_helper'

describe RapSheetProcessor do
  describe '.run' do
    before :each do
      Dir.mkdir '/tmp/autoclearance-rap-sheet-inputs' unless Dir.exist? '/tmp/autoclearance-rap-sheet-inputs'
      Dir.mkdir '/tmp/autoclearance-outputs' unless Dir.exist? '/tmp/autoclearance-outputs'
    end

    after :each do
      FileUtils.rm Dir.glob('/tmp/autoclearance-rap-sheet-inputs/*')
      FileUtils.rm Dir.glob('/tmp/autoclearance-outputs/*')
    end

    it 'reads rap sheets from input bucket and saves conviction data to output bucket' do
      FileUtils.cp('spec/fixtures/skywalker_rap_sheet.pdf', '/tmp/autoclearance-rap-sheet-inputs/')
      FileUtils.cp('spec/fixtures/chewbacca_rap_sheet.pdf', '/tmp/autoclearance-rap-sheet-inputs/')

      travel_to Time.new(2010, 1, 2, 01, 04, 44) do
        described_class.run
      end

      expect(Dir['/tmp/autoclearance-rap-sheet-inputs/*']).to eq []
      expect(Dir['/tmp/autoclearance-outputs/*']).to contain_exactly(
        '/tmp/autoclearance-outputs/skywalker_rap_sheet.csv',
        '/tmp/autoclearance-outputs/chewbacca_rap_sheet.csv',
        '/tmp/autoclearance-outputs/summary_20100102-010444.csv'
      )

      skywalker_expected_text = File.read('spec/fixtures/skywalker_rap_sheet.csv')
      skywalker_actual_text = File.read('/tmp/autoclearance-outputs/skywalker_rap_sheet.csv')
      expect(skywalker_actual_text).to eq(skywalker_expected_text)

      chewbacca_expected_text = File.read('spec/fixtures/chewbacca_rap_sheet.csv')
      chewbacca_actual_text = File.read('/tmp/autoclearance-outputs/chewbacca_rap_sheet.csv')
      expect(chewbacca_actual_text).to eq(chewbacca_expected_text)
     
      summary_expected_text = File.read('spec/fixtures/summary.csv')
      summary_actual_text = File.read('/tmp/autoclearance-outputs/summary_20100102-010444.csv')
      expect(summary_actual_text).to eq(summary_expected_text)
    end

    it 'catches exceptions in the parser and logs the error to an output file' do
      FileUtils.cp('spec/fixtures/not_a_valid_rap_sheet.pdf', '/tmp/autoclearance-rap-sheet-inputs/')
      FileUtils.cp('spec/fixtures/skywalker_rap_sheet.pdf', '/tmp/autoclearance-rap-sheet-inputs/')

      expected_error_message = 'Error: Not a valid RAP sheet'

      allow_any_instance_of(RapSheetParser::Parser).to receive(:parse).and_wrap_original do |m, *args|
        if args[0].include? 'not_a_valid_rap_sheet'
          raise RapSheetParser::RapSheetParserException.new(double('parser', :failure_reason => expected_error_message), '')
        else
          m.call(*args)
        end
      end

      travel_to Time.new(2010, 1, 2, 01, 04, 44) do
        described_class.run
      end

      expect(Dir['/tmp/autoclearance-rap-sheet-inputs/*']).to eq ['/tmp/autoclearance-rap-sheet-inputs/not_a_valid_rap_sheet.pdf']
      expect(Dir['/tmp/autoclearance-outputs/*']).to contain_exactly(
        '/tmp/autoclearance-outputs/not_a_valid_rap_sheet.error',
        '/tmp/autoclearance-outputs/summary_20100102-010444.error',
        '/tmp/autoclearance-outputs/skywalker_rap_sheet.csv',
        '/tmp/autoclearance-outputs/summary_20100102-010444.csv'
      )

      actual_error = File.read('/tmp/autoclearance-outputs/not_a_valid_rap_sheet.error')
      actual_summary_error = File.read('/tmp/autoclearance-outputs/summary_20100102-010444.error')

      expect(actual_error).to include(expected_error_message)
      expect(actual_summary_error).to include('not_a_valid_rap_sheet.pdf:')
      expect(actual_summary_error).to include(expected_error_message)
    end
  end

  describe '.get_pdf_text' do
    it 'extracts the RAP sheet text from the PDF' do
      reader = PDF::Reader.new('spec/fixtures/skywalker_rap_sheet.pdf')

      expected_text = File.read('spec/fixtures/skywalker_rap_sheet.txt')
      actual_text = described_class.get_pdf_text(reader)

      expect(strip_whitespace(actual_text)).to eq(strip_whitespace(expected_text))
    end
  end

  describe '.strip_page_header_and_footer' do
    let :expected_text do
      expected_text = <<~EXPECTED_TEXT
        document begin here
        another line
      EXPECTED_TEXT
    end

    it 'removes blank lines and whitespace at the beginning of page' do
      input_text = <<~INPUT_TEXT

            
              \t

        document begin here
        another line
      INPUT_TEXT

      expect(described_class.strip_page_header_and_footer(input_text)).to eq expected_text
    end

    it 'removes blank lines and whitespace at the end of page' do
      input_text = <<~INPUT_TEXT
        document begin here
        another line

            
              \t

      INPUT_TEXT

      expect(described_class.strip_page_header_and_footer(input_text)).to eq expected_text
    end

    it 'removes lines beginning with "Page" from beginning of page' do
      input_text = <<~INPUT_TEXT

                  Page 1 of 5

        document begin here
        another line
      INPUT_TEXT

      expect(described_class.strip_page_header_and_footer(input_text)).to eq expected_text
    end

    it 'removes lines beginning with "Route" from beginning of page' do
      input_text = <<~INPUT_TEXT

                  
          Route  Print

        document begin here
        another line
      INPUT_TEXT

      expect(described_class.strip_page_header_and_footer(input_text)).to eq expected_text
    end

    it 'removes lines beginning with "http://" from end of page' do
      input_text = <<~INPUT_TEXT
        document begin here
        another line
        http://example.com

      INPUT_TEXT

      expect(described_class.strip_page_header_and_footer(input_text)).to eq expected_text
    end

    it 'removes lines beginning with "https://" from end of page' do
      input_text = <<~INPUT_TEXT
        document begin here
        another line


             https://example.com   5/16/1997
      INPUT_TEXT

      expect(described_class.strip_page_header_and_footer(input_text)).to eq expected_text
    end

    it 'removes lines beginning with "file://" or "ﬁle://" from end of page' do
      input_text = <<~INPUT_TEXT
        document begin here
        another line
             ﬁle:///example.com   5/16/1997

        file:///path/to/file

      INPUT_TEXT

      expect(described_class.strip_page_header_and_footer(input_text)).to eq expected_text
    end
  end

  def strip_whitespace str
    str.gsub(/[\s\n]/, '')
  end
end
