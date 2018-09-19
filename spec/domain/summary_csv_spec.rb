require 'rails_helper'
require 'csv'

describe SummaryCSV do
  let(:eligibility1) do
    court_count1 = build_count(
      code: 'HS',
      section: '11360',
      disposition: build_disposition(
        type: 'convicted',
        sentence: RapSheetParser::ConvictionSentence.new(jail: 2.days),
        severity: 'M'
      )
    )
    eligible_event1 = build_court_event(
      date: Date.new(1994, 1, 2),
      case_number: 'DEF',
      courthouse: 'CASC San Francisco',
      counts: [court_count1],
      name_code: '001'
    )
    rap_sheet1 = build_rap_sheet(
      events: [eligible_event1],
      personal_info: personal_info
    )

    build_rap_sheet_with_eligibility(rap_sheet: rap_sheet1)
  end

  let(:eligibility2) do
    court_count2 = build_count(
      code: 'HS',
      section: '11357',
      disposition: build_disposition(
        type: 'convicted',
        sentence: RapSheetParser::ConvictionSentence.new(jail: 5.days),
        severity: 'M'
      )
    )
    eligible_event2 = build_court_event(
      date: Date.new(1994, 1, 2),
      case_number: 'ABC',
      courthouse: 'CASC San Francisco Co',
      counts: [court_count2],
      name_code: '002'
    )
    rap_sheet2 = build_rap_sheet(
      events: [eligible_event2],
      personal_info: build_personal_info(names: { '002' => 'n a m e' })
    )

    build_rap_sheet_with_eligibility(rap_sheet: rap_sheet2)
  end

  let(:personal_info) { build_personal_info(names: { '001' => 'defendant' }) }

  it 'generates text for a CSV containing eligibility results' do
    summary_csv = described_class.new
    summary_csv.append('filename1', eligibility1)
    summary_csv.append('filename2', eligibility2)

    subject = summary_csv.text

    expect(subject).to include 'filename1,defendant,1994-01-02,DEF,CASC San Francisco,HS 11360,M,2d jail,"",false,false,redesignation,yes,false'
    expect(subject).to include 'filename2,n a m e,1994-01-02,ABC,CASC San Francisco Co,HS 11357,M,5d jail,"",false,false,redesignation,yes,false'
  end

  context 'missing personal info' do
    let(:personal_info) {}

    it 'skips names if missing personal info' do
      summary_csv = described_class.new
      summary_csv.append('filename1', eligibility1)

      subject = summary_csv.text

      expect(subject).to include 'filename1,,1994-01-02,DEF,CASC San Francisco,HS 11360,M,2d jail,"",false,false,redesignation,yes,false'
    end
  end

  it 'adds deceased events to single csv' do
    deceased_event = build_other_event(event_type: 'deceased')
    court_count = build_count(
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
    rap_sheet = build_rap_sheet(events: [eligible_event, deceased_event], personal_info: personal_info)
    eligibility = build_rap_sheet_with_eligibility(rap_sheet: rap_sheet)

    summary_csv = described_class.new
    summary_csv.append('filename1', eligibility)

    subject = summary_csv.text

    expect(subject).to include 'filename1,defendant,1994-01-02,DEF,CASC San Francisco,HS 11360,M,2d jail,"",false,false,redesignation,yes,true'
  end
end
