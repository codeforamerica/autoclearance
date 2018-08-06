require 'rails_helper'
require 'rap_sheet_parser'
require_relative '../../app/domain/count_with_eligibility'
require_relative '../../app/domain/event_with_eligibility'
require_relative '../../app/domain/rap_sheet_with_eligibility'

describe RapSheetWithEligibility do
  describe '#eligible_events' do
    it 'filters out events not in San Francisco' do
      eligible_event = build_court_event(
        courthouse: 'CASC San Francisco'
      )
      ineligible_event = build_court_event(
        courthouse: 'CASO San Francisco'
      )
      south_san_francisco_event = build_court_event(
        courthouse: 'CASC South San Francisco',
      )
      rap_sheet = build_rap_sheet(events: [eligible_event, ineligible_event, south_san_francisco_event])

      subject = new_rap_sheet(rap_sheet).eligible_events
      expect(subject.length).to eq 1
      expect(subject[0].case_number).to eq '12345'
    end

    it 'filters out events dismissed by PC1203' do
      eligible_event = build_court_event(
        courthouse: 'CASC San Francisco'
      )
      ineligible_event = build_court_event(
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

  describe '#has_three_convictions_of_same_type?' do
    it 'returns true if rap sheet contains three convictions with the same code section' do
      count_1 = build_court_count(code: 'PC', section: '123')
      event_1 = build_court_event(counts: [count_1])

      count_2 = build_court_count(code: 'PC', section: '123')
      event_2 = build_court_event(counts: [count_2])

      count_3 = build_court_count(code: 'PC', section: '123')
      event_3 = build_court_event(counts: [count_3])

      rap_sheet = build_rap_sheet(events: ([event_1, event_2, event_3]))

      expect(new_rap_sheet(rap_sheet).has_three_convictions_of_same_type?('PC 123')).to eq true
    end

    it 'returns false if rap sheet does not contain two convictions and one dismissed count for the same code section' do
      count_1 = build_court_count(code: 'PC', section: '123', disposition: 'convicted')
      event_1 = build_court_event(counts: [count_1])

      count_2 = build_court_count(code: 'PC', section: '123', disposition: 'convicted')
      event_2 = build_court_event(counts: [count_2])

      count_3 = build_court_count(code: 'PC', section: '123', disposition: 'dismissed')
      event_3 = build_court_event(counts: [count_3])

      rap_sheet = build_rap_sheet(events: ([event_1, event_2, event_3]))

      expect(new_rap_sheet(rap_sheet).has_three_convictions_of_same_type?('PC 123')).to eq false
    end

    it 'returns false if rap sheet contains three convictions for the same code section in two events' do
      count_1 = build_court_count(code: 'PC', section: '123')
      count_2 = build_court_count(code: 'PC', section: '123')
      event_1 = build_court_event(counts: [count_1, count_2])

      count_3 = build_court_count(code: 'PC', section: '123')
      event_2 = build_court_event(counts: [count_3])

      rap_sheet = build_rap_sheet(events: ([event_1, event_2]))

      expect(new_rap_sheet(rap_sheet).has_three_convictions_of_same_type?('PC 123')).to eq false
    end
  end

  context 'warnings for rap sheets with nothing potentially eligible' do
    it 'saves warnings for rap sheets that did not seem to have any potentially prop64 eligible counts' do
      count = build_court_count(code: 'HS', section: '1234')
      events = [build_court_event(counts: [count], courthouse: 'CASC San Francisco')]
      rap_sheet = build_rap_sheet(events: events)

      warning_file = StringIO.new
      new_rap_sheet(rap_sheet, logger: Logger.new(warning_file))

      expect(warning_file.string).to include('No eligible prop64 convictions found')
    end
  end

  describe '#disqualifiers?' do
    let(:code_section) {}

    subject { new_rap_sheet(build_rap_sheet(events: events)) }

    context 'sex offender registration' do
      let(:events) { [RapSheetParser::RegistrationEvent.new(date: Date.today, code_section: 'PC 290')] }

      it 'returns true if registered sex offender' do
        expect(subject.disqualifiers?(code_section)).to eq true
      end
    end

    context 'superstrike on rap sheet' do
      let(:events) {
        superstrike = build_court_count(code: 'PC', section: '187')
        [build_court_event(counts: [superstrike])]
      }

      it 'returns true if superstrike' do
        expect(subject.disqualifiers?(code_section)).to eq true
      end
    end

    context 'three distinct conviction events which include the same eligible code_section' do
      let(:events) {
        event1_count = build_court_count(code: 'HS', section: '11357')
        event_1 = build_court_event(case_number: '111', counts: [event1_count])

        event2_count = build_court_count(code: 'HS', section: '11357')
        event_2 = build_court_event(case_number: '222', counts: [event2_count])

        event3_count = build_court_count(code: 'HS', section: '11357')
        event_3 = build_court_event(case_number: '333', counts: [event3_count])

        [event_1, event_2, event_3]
      }

      it 'returns true' do
        expect(subject.disqualifiers?('HS 11357')).to eq true
      end
    end
  end

  def new_rap_sheet(rap_sheet, logger: Logger.new(StringIO.new))
    described_class.new(rap_sheet, logger: logger)
  end
end
