require 'rails_helper'

describe RapSheetWithEligibility do
  describe '#eligible_events' do
    it 'filters out events not in San Francisco' do
      eligible_event = RapSheetParser::ConvictionEvent.new(
        date: Date.today,
        case_number: '12345',
        courthouse: 'CASC San Francisco',
        sentence: nil
      )
      ineligible_event = RapSheetParser::ConvictionEvent.new(
        date: Date.today,
        case_number: '12345',
        courthouse: 'CASC Los Angeles',
        sentence: nil
      )
      rap_sheet = RapSheetParser::RapSheet.new([eligible_event, ineligible_event])

      expect(described_class.new(rap_sheet).eligible_events).to eq [eligible_event]
    end

    it 'logs events that appear to be from San Fransisco, but do not match a known courthouse' do
      unknown_courthouse_event = RapSheetParser::ConvictionEvent.new(
        date: Date.today,
        case_number: '12345',
        courthouse: 'CAMC SAN FRANCISCO',
        sentence: nil
      )
      rap_sheet = RapSheetParser::RapSheet.new([unknown_courthouse_event])

      expect(Rails.logger).to receive(:warn).with('Unknown Courthouse: CAMC SAN FRANCISCO')

      expect(described_class.new(rap_sheet).eligible_events).to eq [unknown_courthouse_event]
    end
  end
end
