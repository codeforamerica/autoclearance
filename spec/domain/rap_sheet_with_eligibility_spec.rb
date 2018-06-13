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

  describe '#has_two_prior_convictions_of_same_type?' do
    it 'returns true if rap sheet contains two priors with ' +
      'the same code section and with event dates on the ' +
      'same day or before' do

      event_1 = RapSheetParser::ConvictionEvent.new(
        date: Date.today - 7.days,
        case_number: '1',
        courthouse: 'CASC San Francisco',
        sentence: nil
      )
      count_1 = RapSheetParser::ConvictionCount.new(
        event: event_1,
        code_section_description: nil,
        severity: nil,
        code: 'PC',
        section: '123'
      )
      event_1.counts = [count_1]

      event_2 = RapSheetParser::ConvictionEvent.new(
        date: Date.today - 3.days,
        case_number: '2',
        courthouse: 'CASC Los Angeles',
        sentence: nil
      )
      count_2 = RapSheetParser::ConvictionCount.new(
        event: event_2,
        code_section_description: nil,
        severity: nil,
        code: 'PC',
        section: '123'
      )
      event_2.counts = [count_2]

      event_3 = RapSheetParser::ConvictionEvent.new(
        date: Date.today,
        case_number: '456',
        courthouse: nil,
        sentence: nil
      )
      count_3 = RapSheetParser::ConvictionCount.new(
        event: event_3,
        code_section_description: nil,
        severity: nil,
        code: 'PC',
        section: '123'
      )
      event_3.counts = [count_3]

      rap_sheet = RapSheetParser::RapSheet.new([event_1, event_2, event_3])

      expect(described_class.new(rap_sheet).has_two_prior_convictions_of_same_type?(count_1)).to eq false
      expect(described_class.new(rap_sheet).has_two_prior_convictions_of_same_type?(count_2)).to eq false
      expect(described_class.new(rap_sheet).has_two_prior_convictions_of_same_type?(count_3)).to eq true
    end
  end
end
