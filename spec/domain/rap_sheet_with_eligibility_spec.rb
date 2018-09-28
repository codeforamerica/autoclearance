require 'rails_helper'
require 'rap_sheet_parser'
require_relative '../../app/domain/rap_sheet_with_eligibility'

describe RapSheetWithEligibility do
  describe '#eligible_events' do
    it 'filters out events not in given county' do
      eligible_event1 = build_court_event(
        courthouse: 'Some courthouse',
        case_number: 'abc'
      )
      eligible_event2 = build_court_event(
        courthouse: 'Another courthouse',
        case_number: 'def'
      )
      ineligible_event = build_court_event(
        courthouse: 'ineligible courthouse'
      )
      rap_sheet = build_rap_sheet(events: [eligible_event1, eligible_event2, ineligible_event])

      subject = build_rap_sheet_with_eligibility(
        rap_sheet: rap_sheet, county: build_county(courthouses: ['Some courthouse', 'Another courthouse'])
      ).eligible_events
      expect(subject.length).to eq 2
      expect(subject[0].case_number).to eq 'abc'
      expect(subject[1].case_number).to eq 'def'
    end

    it 'filters out events dismissed by PC1203' do
      eligible_event = build_court_event
      ineligible_event = build_court_event(
        counts: [
          build_count(
            updates: [
              RapSheetParser::Update.new(dispositions: [build_disposition(type: 'pc1203_dismissed')])
            ]
          )
        ]
      )
      rap_sheet = build_rap_sheet(events: [eligible_event, ineligible_event])

      expect(build_rap_sheet_with_eligibility(rap_sheet: rap_sheet).eligible_events).to eq [eligible_event]
    end
  end

  describe '#has_three_convictions_of_same_type?' do
    it 'returns true if rap sheet contains three convictions with the same code section' do
      event1 = build_court_event(counts: [build_count(code: 'PC', section: '123')])
      event2 = build_court_event(counts: [build_count(code: 'PC', section: '123')])
      event3 = build_court_event(counts: [build_count(code: 'PC', section: '123')])

      rap_sheet = build_rap_sheet(events: [event1, event2, event3])

      expect(build_rap_sheet_with_eligibility(rap_sheet: rap_sheet).has_three_convictions_of_same_type?('PC 123')).to eq true
    end

    it 'returns false if rap sheet does not contain two convictions and one dismissed count for the same code section' do
      event1 = build_court_event(counts: [build_count(code: 'PC', section: '123', disposition: build_disposition(type: 'convicted'))])
      event2 = build_court_event(counts: [build_count(code: 'PC', section: '123', disposition: build_disposition(type: 'convicted'))])
      event3 = build_court_event(counts: [build_count(code: 'PC', section: '123', disposition: build_disposition(type: 'dismissed'))])

      rap_sheet = build_rap_sheet(events: [event1, event2, event3])

      expect(build_rap_sheet_with_eligibility(rap_sheet: rap_sheet).has_three_convictions_of_same_type?('PC 123')).to eq false
    end

    it 'returns false if rap sheet contains three convictions for the same code section in two events' do
      event1 = build_court_event(
        counts: [
          build_count(code: 'PC', section: '123'),
          build_count(code: 'PC', section: '123')
        ]
      )
      event2 = build_court_event(counts: [build_count(code: 'PC', section: '123')])

      rap_sheet = build_rap_sheet(events: [event1, event2])

      expect(build_rap_sheet_with_eligibility(rap_sheet: rap_sheet).has_three_convictions_of_same_type?('PC 123')).to eq false
    end
  end

  context 'warnings for rap sheets with nothing potentially eligible' do
    it 'saves warnings for rap sheets that did not seem to have any potentially prop64 eligible counts' do
      count = build_count(code: 'HS', section: '1234')
      events = [build_court_event(counts: [count], courthouse: 'CASC San Francisco')]
      rap_sheet = build_rap_sheet(events: events)

      warning_file = StringIO.new
      build_rap_sheet_with_eligibility(rap_sheet: rap_sheet, logger: Logger.new(warning_file))

      expect(warning_file.string).to include('No eligible prop64 convictions found')
    end
  end

  describe '#disqualifiers?' do
    let(:code_section) {}

    subject { build_rap_sheet_with_eligibility(rap_sheet: build_rap_sheet(events: events)) }

    context 'sex offender registration' do
      let(:events) do
        [
          build_other_event(
            event_type: 'registration',
            counts: [build_count(code: 'PC', section: '290')]
          )
        ]
      end

      it 'returns true if registered sex offender' do
        expect(subject.disqualifiers?).to eq true
      end
    end

    context 'superstrike on rap sheet' do
      let(:events) do
        superstrike = build_count(code: 'PC', section: '187')
        [build_court_event(counts: [superstrike])]
      end

      it 'returns true if superstrike' do
        expect(subject.disqualifiers?).to eq true
      end
    end

    context 'none of the above' do
      let(:events) do
        event1_count = build_count(code: 'HS', section: '11357')
        [build_court_event(case_number: '111', counts: [event1_count])]
      end

      it 'returns false' do
        expect(subject.disqualifiers?).to eq false
      end
    end
  end
end
