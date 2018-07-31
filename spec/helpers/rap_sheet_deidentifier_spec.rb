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
      output_files = Dir['/tmp/autoclearance-outputs/redacted_rap_sheet_*']
      expect(output_files.length).to eq 1

      skywalker_actual_text = File.read(output_files[0])
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
    end
  end
end
