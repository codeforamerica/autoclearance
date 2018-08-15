require 'rails_helper'

RSpec.describe FillProp64Motion do
  let(:personal_info) {
    build_personal_info(names: {
      '01' => 'SINGLETON, SYMONNE',
      '03' => 'DAVE'
    })
  }

  let(:counts) {
    [
      build_court_count(code: 'HS', section: '11357(a)'),
      build_court_count(code: 'HS', section: '11357(a)'),
      build_court_count(code: 'HS', section: '11359')
    ]
  }

  let(:event) {
    build_court_event(
      name_code: name_code,
      case_number: 'MYCASE01',
      date: Date.new(1994, 1, 2)
    )
  }

  subject {
    event_with_eligibility = EventWithEligibility.new(event)

    file = described_class.new(counts, event_with_eligibility, personal_info).filled_motion

    get_fields_from_pdf(file)
  }

  context 'rap sheet with name code different than the first' do
    let(:name_code) { '03' }

    it 'fills out fields' do
      fields = subject

      expect(fields["Defendant"]).to eq "SINGLETON, SYMONNE AKA DAVE"
      expect(fields["SCN"]).to eq "MYCASE01"
      expect(fields["FOR RESENTENCING OR DISMISSAL HS  113618b"]).to eq 'Off'
      expect(fields["FOR REDESIGNATION OR DISMISSALSEALING HS  113618f"]).to eq 'On'
      expect(fields["11357  Possession of Marijuana"]).to eq('On')
      expect(fields["11357 Count"]).to eq('x2')
      expect(fields["11358  Cultivation of Marijuana"]).to eq('Off')
      expect(fields["11358 Count"]).to eq('')
      expect(fields["11359  Possession of Marijuana for Sale"]).to eq('On')
      expect(fields["11359 Count"]).to eq('')
      expect(fields["11360  Transportation Distribution or"]).to eq('Off')
      expect(fields["11360 Count"]).to eq('')
      expect(fields["Other Health and Safety Code Section"]).to eq 'Off'
      expect(fields["Text2"]).to eq ''
    end
  end

  context 'rap sheet with code sections not found on the checkboxes' do
    let(:name_code) { '03' }
    let(:counts) {
      [
        build_court_count(code: 'PC', section: '32'),
        build_court_count(code: 'PC', section: '32'),
        build_court_count(code: 'PC', section: '123')
      ]
    }

    it 'fills out the Other field with code_section' do
      fields = subject

      expect(fields["Other Health and Safety Code Section"]).to eq 'On'
      expect(fields["Text2"]).to eq 'PC 32 x2, PC 123'
    end
  end

  context 'name code is the same as the first' do
    let(:name_code) { '01' }

    it "only includes the primary name if the event name is the same as the primary name" do
      fields = subject

      expect(fields["Defendant"]).to eq "SINGLETON, SYMONNE"
    end
  end

  context 'a redacted rap sheet' do
    let(:personal_info) { nil }
    let(:name_code) { '01' }
    it 'fills out fields' do
      fields = subject

      expect(fields["Defendant"]).to eq ''
    end
  end
end
