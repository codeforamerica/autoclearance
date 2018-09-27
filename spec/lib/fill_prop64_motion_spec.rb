require 'rails_helper'

RSpec.describe FillProp64Motion do
  let(:personal_info) do
    build_personal_info(names: {
      '01' => 'SAYS, SIMON',
      '03' => 'DAVE'
    })
  end

  let(:counts) do
    [
      build_count(code: 'HS', section: '11357(a)'),
      build_count(code: 'HS', section: '11357(a)'),
      build_count(code: 'HS', section: '11359')
    ]
  end

  let(:event) do
    build_court_event(
      name_code: name_code,
      case_number: 'MYCASE01',
      date: Date.new(1994, 1, 2)
    )
  end

  let(:ada) { { name: 'Some Attorney', state_bar_number: '8675309' } }

  subject do
    eligibility = build_rap_sheet_with_eligibility(rap_sheet: build_rap_sheet)
    event_with_eligibility = EventWithEligibility.new(event: event, eligibility: eligibility)

    file = described_class.new(ada, counts, event_with_eligibility, personal_info).filled_motion

    get_fields_from_pdf(file)
  end

  context 'rap sheet with name code different than the first' do
    let(:name_code) { '03' }

    it 'fills out fields' do
      fields = subject

      expect(fields['Assistant District Attorney']).to eq 'Some Attorney'
      expect(fields['CA SB']).to eq '8675309'
      expect(fields['Defendant']).to eq 'SAYS, SIMON AKA DAVE'
      expect(fields['SCN']).to eq 'MYCASE01'
      expect(fields['FOR RESENTENCING OR DISMISSAL HS  113618b']).to eq 'Off'
      expect(fields['FOR REDESIGNATION OR DISMISSALSEALING HS  113618f']).to eq 'On'
      expect(fields['11357  Possession of Marijuana']).to eq('On')
      expect(fields['11357 Count']).to eq('x2')
      expect(fields['11358  Cultivation of Marijuana']).to eq('Off')
      expect(fields['11358 Count']).to eq('')
      expect(fields['11359  Possession of Marijuana for Sale']).to eq('On')
      expect(fields['11359 Count']).to eq('')
      expect(fields['11360  Transportation Distribution or']).to eq('Off')
      expect(fields['11360 Count']).to eq('')
      expect(fields['Other Health and Safety Code Section']).to eq 'Off'
      expect(fields['Text2']).to eq ''
      expect(fields['The District Attorney finds that defendant is eligible for relief and now requests the court to recall and resentence']).to eq 'On'
    end
  end

  context 'rap sheet with code sections not found on the checkboxes' do
    let(:name_code) { '03' }
    let(:counts) do
      [
        build_count(code: 'PC', section: '32'),
        build_count(code: 'PC', section: '32'),
        build_count(code: 'PC', section: '123')
      ]
    end

    it 'fills out the Other field with code_section' do
      fields = subject

      expect(fields['Other Health and Safety Code Section']).to eq 'On'
      expect(fields['Text2']).to eq 'PC 32 x2, PC 123'
    end
  end

  context 'name code is the same as the first' do
    let(:name_code) { '01' }

    it 'only includes the primary name if the event name is the same as the primary name' do
      fields = subject

      expect(fields['Defendant']).to eq 'SAYS, SIMON'
    end
  end

  context 'a redacted rap sheet' do
    let(:personal_info) { nil }
    let(:name_code) { '01' }
    it 'fills out fields' do
      fields = subject

      expect(fields['Defendant']).to eq ''
    end
  end
end
