require 'spec_helper'
require 'rap_sheet_parser'
require_relative '../../app/domain/event_with_eligibility'
require_relative '../../app/domain/rap_sheet_with_eligibility'

describe RapSheetWithEligibility do
  describe '#eligible_events' do
    it 'filters out events not in San Francisco' do
      eligible_event = RapSheetParser::ConvictionEvent.new(
        date: Date.today,
        case_number: '12345',
        courthouse: 'CASC San Francisco',
        sentence: nil,
        counts: [],
        updates: []
      )
      ineligible_event = RapSheetParser::ConvictionEvent.new(
        date: Date.today,
        case_number: 'abcde',
        courthouse: 'CASO San Francisco',
        sentence: nil,
        counts: [],
        updates: []
      )
      south_san_francisco_event = RapSheetParser::ConvictionEvent.new(
        date: Date.today,
        case_number: '456',
        courthouse: 'CASC South San Francisco',
        sentence: nil,
        counts: [],
        updates: []
      )
      rap_sheet = build_rap_sheet(events: [eligible_event, ineligible_event, south_san_francisco_event])

      subject = described_class.new(rap_sheet).eligible_events
      expect(subject.length).to eq 1
      expect(subject[0].case_number).to eq '12345'
    end

    it 'filters out events dismissed by PC1203' do
      eligible_event = RapSheetParser::ConvictionEvent.new(
        date: Date.today,
        case_number: '12345',
        courthouse: 'CASC San Francisco',
        sentence: nil,
        counts: [],
        updates: []
      )
      ineligible_event = RapSheetParser::ConvictionEvent.new(
        date: Date.today,
        case_number: '39493',
        courthouse: 'CASC San Francisco',
        sentence: nil,
        counts: [],
        updates: [
          RapSheetParser::Update.new(
            dispositions: [RapSheetParser::PC1203DismissedDisposition.new]
          )
        ]
      )
      rap_sheet = build_rap_sheet(events: ([eligible_event, ineligible_event]))

      expect(described_class.new(rap_sheet).eligible_events).to eq [eligible_event]
    end
  end

  describe '#has_two_prior_convictions_of_same_type?' do
    it 'returns true if rap sheet contains two priors with ' +
         'the same code section and with event dates on the ' +
         'same day or before' do

      count_1 = RapSheetParser::ConvictionCount.new(
        code_section_description: nil,
        severity: nil,
        code: 'PC',
        section: '123'
      )
      event_1 = RapSheetParser::ConvictionEvent.new(
        date: Date.today - 7.days,
        case_number: '1',
        courthouse: 'CASC San Francisco',
        sentence: nil,
        updates: nil,
        counts: [count_1]
      )

      count_2 = RapSheetParser::ConvictionCount.new(
        code_section_description: nil,
        severity: nil,
        code: 'PC',
        section: '123'
      )
      event_2 = RapSheetParser::ConvictionEvent.new(
        date: Date.today - 3.days,
        case_number: '2',
        courthouse: 'CASC Los Angeles',
        sentence: nil,
        updates: nil,
        counts: [count_2]
      )

      count_3 = RapSheetParser::ConvictionCount.new(
        code_section_description: nil,
        severity: nil,
        code: 'PC',
        section: '123'
      )
      event_3 = RapSheetParser::ConvictionEvent.new(
        date: Date.today,
        case_number: '456',
        courthouse: nil,
        sentence: nil,
        updates: nil,
        counts: [count_3]
      )

      rap_sheet = build_rap_sheet(events: ([event_1, event_2, event_3]))

      expect(described_class.new(rap_sheet).has_two_prior_convictions_of_same_type?(event_1, count_1)).to eq false
      expect(described_class.new(rap_sheet).has_two_prior_convictions_of_same_type?(event_2, count_2)).to eq false
      expect(described_class.new(rap_sheet).has_two_prior_convictions_of_same_type?(event_3, count_3)).to eq true
    end
  end

  def build_rap_sheet(events: [], personal_info: nil)
    RapSheetParser::RapSheet.new(events: events, personal_info: personal_info)
  end
end
