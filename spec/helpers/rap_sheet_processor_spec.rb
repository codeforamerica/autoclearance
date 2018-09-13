require 'rails_helper'

describe RapSheetProcessor do
  describe '#run' do
    subject do
      travel_to(Time.zone.local(2011, 1, 2, 1, 4, 44)) do
        described_class.new(Counties::SAN_FRANCISCO).run
      end
    end

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

      expect { subject }.to output(Regexp.new('2 RAP sheets produced 1 motion in ([0-9]|\.)+ seconds\n'\
                                   'Added 2 RAP sheets to analysis db. Overwrote 0 existing RAP sheets.')).to_stdout

      expect(Dir['/tmp/autoclearance-rap-sheet-inputs/*']).to be_empty
      expect(Dir['/tmp/autoclearance-outputs/*'])
        .to contain_exactly(
          '/tmp/autoclearance-outputs/summary_20110102-010444.csv',
          '/tmp/autoclearance-outputs/skywalker_rap_sheet_motion_0.pdf'
        )

      skywalker_motion_fields = get_fields_from_pdf(File.open('/tmp/autoclearance-outputs/skywalker_rap_sheet_motion_0.pdf'))
      expect(skywalker_motion_fields['Defendant']).to eq 'SKYWALKER,LUKE JAY'

      summary_expected_text = File.read('spec/fixtures/summary.csv')
      summary_actual_text = File.read('/tmp/autoclearance-outputs/summary_20110102-010444.csv')
      expect(summary_actual_text).to eq(summary_expected_text)
    end

    it 'catches exceptions in the parser and logs the error to an output file' do
      FileUtils.cp('spec/fixtures/not_a_valid_rap_sheet.pdf', '/tmp/autoclearance-rap-sheet-inputs/')
      FileUtils.cp('spec/fixtures/skywalker_rap_sheet.pdf', '/tmp/autoclearance-rap-sheet-inputs/')

      fake_exception = RapSheetParser::RapSheetParserException.new(
        double('parser', failure_reason: 'Error: Not a valid RAP sheet'),
        ''
      )

      allow_any_instance_of(RapSheetParser::Parser).to receive(:parse).and_wrap_original do |m, *args|
        raise fake_exception if args[0].include? 'not_a_valid_rap_sheet'

        m.call(*args)
      end

      expect { subject }.to output(Regexp.new('1 RAP sheet produced 1 motion in ([0-9]|\.)+ seconds\n'\
                                    'Added 1 RAP sheet to analysis db. Overwrote 0 existing RAP sheets.')).to_stdout

      expect(Dir['/tmp/autoclearance-rap-sheet-inputs/*'])
        .to contain_exactly('/tmp/autoclearance-rap-sheet-inputs/not_a_valid_rap_sheet.pdf')
      expect(Dir['/tmp/autoclearance-outputs/*'])
        .to contain_exactly(
          '/tmp/autoclearance-outputs/not_a_valid_rap_sheet.error',
          '/tmp/autoclearance-outputs/summary_20110102-010444.error',
          '/tmp/autoclearance-outputs/summary_20110102-010444.csv',
          '/tmp/autoclearance-outputs/skywalker_rap_sheet_motion_0.pdf'
        )

      actual_error = File.read('/tmp/autoclearance-outputs/not_a_valid_rap_sheet.error')
      actual_summary_error = File.read('/tmp/autoclearance-outputs/summary_20110102-010444.error')

      expect(actual_error).to include('Error: Not a valid RAP sheet')
      expect(actual_summary_error).to include('not_a_valid_rap_sheet.pdf:')
      expect(actual_summary_error).to include('Error: Not a valid RAP sheet')
    end

    it 'sends warnings from the parser to a warnings file' do
      FileUtils.cp('spec/fixtures/not_a_valid_rap_sheet.pdf', '/tmp/autoclearance-rap-sheet-inputs/')

      expect { subject }.to output(Regexp.new('1 RAP sheet produced 0 motions in ([0-9]|\.)+ seconds\n'\
                                  'Added 1 RAP sheet to analysis db. Overwrote 0 existing RAP sheets.')).to_stdout

      actual_warning = File.read('/tmp/autoclearance-outputs/summary_20110102-010444.warning')

      expect(actual_warning).to include("[not_a_valid_rap_sheet.pdf] Unrecognized event:\n[not_a_valid_rap_sheet.pdf] HI")
      expect(actual_warning).to include("[not_a_valid_rap_sheet.pdf] Unrecognized event:\n[not_a_valid_rap_sheet.pdf]   BYE")
    end

    it 'saves a database entry for each rap sheet' do
      FileUtils.cp('spec/fixtures/skywalker_rap_sheet.pdf', '/tmp/autoclearance-rap-sheet-inputs/')

      expect { described_class.new(Counties::SAN_FRANCISCO).run }
        .to output(/1 RAP sheet produced 1 motion in ([0-9]|\.)+ seconds\nAdded 1 RAP sheet to analysis db. Overwrote 0 existing RAP sheets./).to_stdout

      FileUtils.cp('spec/fixtures/skywalker_rap_sheet.pdf', '/tmp/autoclearance-rap-sheet-inputs/')
      FileUtils.cp('spec/fixtures/chewbacca_rap_sheet.pdf', '/tmp/autoclearance-rap-sheet-inputs/')

      expect { described_class.new(Counties::SAN_FRANCISCO).run }
        .to output(/2 RAP sheets produced 1 motion in ([0-9]|\.)+ seconds\nAdded 1 RAP sheet to analysis db. Overwrote 1 existing RAP sheet./).to_stdout

      expect(AnonRapSheet.count).to eq 2
    end
  end
end
