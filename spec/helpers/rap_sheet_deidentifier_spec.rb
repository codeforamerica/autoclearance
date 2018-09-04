require 'rails_helper'

describe RapSheetDeidentifier do
  describe '#run' do
    before :each do
      Dir.mkdir '/tmp/autoclearance-rap-sheet-inputs' unless Dir.exist? '/tmp/autoclearance-rap-sheet-inputs'
      Dir.mkdir '/tmp/autoclearance-outputs' unless Dir.exist? '/tmp/autoclearance-outputs'
    end

    after :each do
      FileUtils.rm Dir.glob('/tmp/autoclearance-rap-sheet-inputs/*')
      FileUtils.rm Dir.glob('/tmp/autoclearance-outputs/*')
    end

    it 'reads rap sheets from input bucket and saves anonymized rap sheets to output bucket' do
      FileUtils.cp('spec/fixtures/skywalker_rap_sheet.pdf', '/tmp/autoclearance-rap-sheet-inputs/')

      described_class.new.run

      expect(Dir['/tmp/autoclearance-rap-sheet-inputs/*'].length).to eq 1
      redacted_text = Dir['/tmp/autoclearance-outputs/redacted_rap_sheet_*.txt']
      expect(redacted_text.length).to eq 1

      skywalker_actual_text = File.read(redacted_text[0])
      expect(skywalker_actual_text).to include('496 PC-RECEIVE/ETC KNOWN STOLEN PROPERTY')
      expect(skywalker_actual_text).not_to include('SKYWALKER')
      expect(skywalker_actual_text).not_to include('LUKE')
      expect(skywalker_actual_text).not_to include('JAY')
      expect(skywalker_actual_text).not_to include('A99000099')
      expect(skywalker_actual_text).not_to include('19660119')
      expect(skywalker_actual_text).not_to include('19550505')
      expect(skywalker_actual_text).not_to include('#1111111')
      expect(skywalker_actual_text).not_to include('#1234567')
      expect(skywalker_actual_text).not_to include('#2222222')
      expect(skywalker_actual_text).not_to include('#3456789')
      expect(skywalker_actual_text).not_to include('#33857493')

      redacted_pdf = Dir['/tmp/autoclearance-outputs/redacted_rap_sheet_*.pdf']
      expect(redacted_pdf.length).to eq 1

      pdf_text = PDFReader.new(File.read(redacted_pdf[0])).text
      expect(pdf_text).to include('CII/A01234557')
      expect(pdf_text).to include('496 PC-RECEIVE/ETC KNOWN STOLEN PROPERTY')
      expect(pdf_text).not_to include('SKYWALKER')
      expect(pdf_text).not_to include('LUKE')
      expect(pdf_text).not_to include('JAY')
      expect(pdf_text).not_to include('A99000099')
      expect(pdf_text).not_to include('19660119')
      expect(pdf_text).not_to include('19550505')
      expect(pdf_text).not_to include('#1111111')
      expect(pdf_text).not_to include('#1234567')
      expect(pdf_text).not_to include('#2222222')
      expect(pdf_text).not_to include('#3456789')
      expect(pdf_text).not_to include('#33857493')
    end

    it 'skip rap sheets without any cycles' do
      File.open('/tmp/autoclearance-rap-sheet-inputs/bad_rap_sheet.pdf', 'w')

      expect_any_instance_of(PDFReader).to receive(:text).and_return('Personal info')

      described_class.new.run

      expect(Dir['/tmp/autoclearance-outputs/*'].length).to eq 0
    end

    it 'allows for nbsp in cycle delimiters' do
      File.open('/tmp/autoclearance-rap-sheet-inputs/example_rap_sheet.pdf', 'w')

      # cycle delimiter below contains invisible nbsp characters
      rap_sheet_text = <<~TEXT
        personal info
        * * * *
        cycle text
        * * * END OF MESSAGE * * *
      TEXT

      expect_any_instance_of(PDFReader).to receive(:text).and_return(rap_sheet_text)

      described_class.new.run

      expect(Dir['/tmp/autoclearance-outputs/*.txt'].length).to eq 1
    end

    it 'allows for invalid dates of birth' do
      File.open('/tmp/autoclearance-rap-sheet-inputs/example_rap_sheet.pdf', 'w')

      rap_sheet_text = <<~TEXT
        personal info
        * * * *
        DOB:19910000
        * * * END OF MESSAGE * * *
      TEXT

      expect_any_instance_of(PDFReader).to receive(:text).and_return(rap_sheet_text)

      described_class.new.run
      output_text_files = Dir['/tmp/autoclearance-outputs/*.txt']
      expect(output_text_files.length).to eq 1
      actual_text = File.read(output_text_files[0])
      expect(actual_text).not_to include('19910000')
    end
  end
end
