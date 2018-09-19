require 'spec_helper'
require 'csv'
require 'pdf-forms'
require_relative '../../app/lib/fill_misdemeanor_petitions'

describe FillMisdemeanorPetitions do
  it 'populates motions per row' do
    t = Tempfile.new("test_csv")
    t << "some_headers\n"
    t << "123, 010101, SMITH/AGENT   ,1/1/99,,,,,,  #N/A , #N/A ,11357©, #N/A, , , , #N/A, ,   \n"
    t << "456, 293848, CANDY/AGENT   ,1/1/99,,,,,,  11357(a) , #N/A , #N/A, #N/A , 11359(a), #N/A,11360(a),,   \n"
    t.close

    output_dir = Dir.mktmpdir

    travel_to Date.new(1999, 10, 1) do
      described_class.new(path: t, output_dir: output_dir).fill
    end

    expect(Dir["#{output_dir}/**/*.pdf"].length).to eq 2

    fields = get_fields_from_pdf(File.new("#{output_dir}/with_sf_number/petition_SMITH_AGENT_123.pdf"))

    expect(fields).to eq(
      "defendant" => "SMITH/AGENT (DOB 1/1/99)",
      "sf_number" => "010101",
      "court_number" => "123",
      "11357a" => "No",
      "11357b" => "No",
      "11357c" => "Yes",
      "11360b" => "No",
      "others" => "No",
      "other_charges_description" => "",
      "date" => "1999-10-01",
      "completed_sentence" => "Yes",
      "court_dismisses" => "Yes",
      "court_granted" => "Yes",
      "court_relieved" => "Yes",
      "court_sealed" => "Yes",
      "record_sealed" => "Yes",
      "dismissal" => "Yes"
    )

    fields = get_fields_from_pdf(File.new("#{output_dir}/with_sf_number/petition_CANDY_AGENT_456.pdf"))
    expect(fields).to eq(
      "defendant" => "CANDY/AGENT (DOB 1/1/99)",
      "sf_number" => "293848",
      "court_number" => "456",
      "11357a" => "Yes",
      "11357b" => "No",
      "11357c" => "No",
      "11360b" => "No",
      "others" => "Yes",
      "other_charges_description" => "11359(a), 11360(a)",
      "date" => "1999-10-01",
      "completed_sentence" => "Yes",
      "court_dismisses" => "Yes",
      "court_granted" => "Yes",
      "court_relieved" => "Yes",
      "court_sealed" => "Yes",
      "record_sealed" => "Yes",
      "dismissal" => "Yes"
    )
  end

  it 'does not fill in sf number if it is zero' do
    t = Tempfile.new("test_csv")
    t << "some_headers\n"
    t << "123, 0 , SMITH/AGENT   ,1/1/99,,,,,,  #N/A , #N/A ,11357(c), #N/A, , , , #N/A, ,   \n"
    t.close

    output_dir = Dir.mktmpdir
    described_class.new(path: t, output_dir: output_dir).fill
    expect(Dir["#{output_dir}/**/*.pdf"].length).to eq 1

    fields = get_fields_from_pdf(File.new("#{output_dir}/no_sf_number/petition_SMITH_AGENT_123.pdf"))

    expect(fields["sf_number"]).to eq ''
  end
end
