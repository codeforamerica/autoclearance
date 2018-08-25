require 'rails_helper'
require 'csv'

describe SingleCSV do
  it 'generates text for a CSV containing eligibility results' do
    court_count = build_court_count(
      code: 'HS',
      section: '11360',
      disposition: build_disposition(
        type: 'convicted',
        sentence: RapSheetParser::ConvictionSentence.new(jail: 2.days),
        severity: 'M'
      )
    )
    eligible_event = build_court_event(
      date: Date.new(1994, 1, 2),
      case_number: 'DEF',
      courthouse: 'CASC San Francisco',
      counts: [court_count],
      name_code: '001'
    )
    personal_info = build_personal_info(names: {'001' => 'defendant'})
    rap_sheet = build_rap_sheet(events: [eligible_event], personal_info: personal_info)
    eligibility = build_rap_sheet_with_eligibility(rap_sheet: rap_sheet)

    subject = described_class.new(eligibility).text

    expect(subject).to include 'defendant,1994-01-02,DEF,CASC San Francisco,HS 11360,M,2d jail,"",false,false,redesignation,true'
  end

  it 'skips names if missing personal info' do
    court_count = build_court_count(
      code: 'HS',
      section: '11360',
      disposition: build_disposition(
        type: 'convicted',
        sentence: RapSheetParser::ConvictionSentence.new(jail: 2.days),
        severity: 'M'
      )
    )
    eligible_event = build_court_event(
      date: Date.new(1994, 1, 2),
      case_number: 'DEF',
      courthouse: 'CASC San Francisco',
      counts: [court_count],
      name_code: '001'
    )
    rap_sheet = build_rap_sheet(events: [eligible_event], personal_info: nil)
    eligibility = build_rap_sheet_with_eligibility(rap_sheet: rap_sheet)

    subject = described_class.new(eligibility).text

    expect(subject).to include ',1994-01-02,DEF,CASC San Francisco,HS 11360,M,2d jail,"",false,false,redesignation,true'
  end

  it 'adds deceased events to single csv' do
    deceased_event = build_other_event(
      header: 'deceased',
      agency: 'CACO San Francisco'
    )

    court_count = build_court_count(
      code: 'HS',
      section: '11360',
      disposition: build_disposition(
        type: 'convicted',
        sentence: RapSheetParser::ConvictionSentence.new(jail: 2.days),
        severity: 'M'
      )
    )
    eligible_event = build_court_event(
      date: Date.new(1994, 1, 2),
      case_number: 'DEF',
      courthouse: 'CASC San Francisco',
      counts: [court_count],
      name_code: '001'
    )

    personal_info = build_personal_info(names: {'001' => 'defendant'})
    rap_sheet = build_rap_sheet(events: [eligible_event, deceased_event], personal_info: personal_info)
    eligibility = build_rap_sheet_with_eligibility(rap_sheet: rap_sheet)

    subject = described_class.new(eligibility).text

    expect(subject).to include 'defendant,1994-01-02,DEF,CASC San Francisco,HS 11360,M,2d jail,"",false,false,redesignation,true,true'
  end
end
