require 'rails_helper'
require 'rap_sheet_parser'
require_relative '../../app/domain/count_with_eligibility'
require_relative '../../app/domain/event_with_eligibility'
require_relative '../../app/domain/rap_sheet_with_eligibility'

describe RapSheetWithEligibility do
  describe '#eligible_events' do
    it 'filters out events not in San Francisco' do
      eligible_event = build_conviction_event(
        courthouse: 'CASC San Francisco'
      )
      ineligible_event = build_conviction_event(
        courthouse: 'CASO San Francisco'
      )
      south_san_francisco_event = build_conviction_event(
        courthouse: 'CASC South San Francisco',
      )
      rap_sheet = build_rap_sheet(events: [eligible_event, ineligible_event, south_san_francisco_event])

      subject = new_rap_sheet(rap_sheet).eligible_events
      expect(subject.length).to eq 1
      expect(subject[0].case_number).to eq '12345'
    end

    it 'filters out events dismissed by PC1203' do
      eligible_event = build_conviction_event(
        courthouse: 'CASC San Francisco'
      )
      ineligible_event = build_conviction_event(
        courthouse: 'CASC San Francisco',
        updates: [
          RapSheetParser::Update.new(
            dispositions: [RapSheetParser::PC1203DismissedDisposition.new]
          )
        ]
      )
      rap_sheet = build_rap_sheet(events: ([eligible_event, ineligible_event]))

      expect(new_rap_sheet(rap_sheet).eligible_events).to eq [eligible_event]
    end
  end

  describe '#has_two_prior_convictions_of_same_type?' do
    it 'returns true if rap sheet contains two priors with ' +
         'the same code section and with event dates on the ' +
         'same day or before' do

      count_1 = build_court_count(code: 'PC', section: '123')
      event_1 = build_conviction_event(
        date: Date.today - 7.days,
        case_number: '1',
        counts: [count_1]
      )

      count_2 = build_court_count(code: 'PC', section: '123')
      event_2 = build_conviction_event(
        date: Date.today - 3.days,
        case_number: '2',
        counts: [count_2]
      )

      count_3 = build_court_count(code: 'PC', section: '123')
      event_3 = build_conviction_event(
        date: Date.today,
        case_number: '456',
        counts: [count_3]
      )

      rap_sheet = build_rap_sheet(events: ([event_1, event_2, event_3]))

      expect(new_rap_sheet(rap_sheet).has_two_prior_convictions_of_same_type?(EventWithEligibility.new(event_1), CountWithEligibility.new(count_1))).to eq true
      expect(new_rap_sheet(rap_sheet).has_two_prior_convictions_of_same_type?(EventWithEligibility.new(event_2), CountWithEligibility.new(count_2))).to eq true
      expect(new_rap_sheet(rap_sheet).has_two_prior_convictions_of_same_type?(EventWithEligibility.new(event_3), CountWithEligibility.new(count_3))).to eq true
    end
  end

  context 'warnings for rap sheets with nothing potentially eligible' do
    it 'saves warnings for rap sheets that did not seem to have any potentially prop64 eligible counts' do
      count = build_court_count(code: 'HS', section: '1234')
      events = [build_conviction_event(counts: [count], courthouse: 'CASC San Francisco')]
      rap_sheet = build_rap_sheet(events: events)

      warning_file = StringIO.new
      new_rap_sheet(rap_sheet, logger: Logger.new(warning_file))

      expect(warning_file.string).to include('No eligible prop64 convictions found')
    end
  end

  def new_rap_sheet(rap_sheet, logger: Logger.new(StringIO.new))
    described_class.new(rap_sheet, logger: logger)
  end
end
