require 'spec_helper'
require 'csv'
require 'pdf-forms'
require_relative '../../app/lib/fill_misdemeanor_petitions'

describe FillMisdemeanorPetitions do
  it 'populates motions per row' do
    t = Tempfile.new("test_csv")
    t << "some_headers\n"
    t << "123,SMITH/AGENT   ,1/1/99,,,,,,  #N/A , #N/A ,11357(c), #N/A, , , , ,  \n"
    t << "123,CANDY/AGENT   ,1/1/99,,,,,,  11357(a) , #N/A , #N/A, #N/A , 11359(a), , , ,   \n"
    t.close

    output_dir = Dir.mktmpdir

    travel_to Date.new(1999, 10, 1) do
      described_class.new(path: t, output_dir: output_dir).fill
    end

    expect(Dir["#{output_dir}/*"].length).to eq 2

    fields = get_fields_from_pdf(File.new("#{output_dir}/petition_SMITH_AGENT.pdf"))
    expect(fields["last name, first name, middle name (DOB)"]).to eq "SMITH/AGENT (DOB 1/1/99)"
    expect(fields["Court Number"]).to eq "123"
    expect(fields["Check Box2"]).to eq ""
    expect(fields["Check Box3"]).to eq ""
    expect(fields["Check Box4"]).to eq "Yes"
    expect(fields["Check Box5"]).to eq ""
    expect(fields["Check Box7"]).to eq ""
    expect(fields["PROSECUTING ATTORNEY REQUEST FOR DISMISSAL AND SEALING"]).to eq ""
    expect(fields["Date"]).to eq "1999-10-01"

    fields = get_fields_from_pdf(File.new("#{output_dir}/petition_CANDY_AGENT.pdf"))
    expect(fields["last name, first name, middle name (DOB)"]).to eq "CANDY/AGENT (DOB 1/1/99)"
    expect(fields["Court Number"]).to eq "123"
    expect(fields["Check Box2"]).to eq "Yes"
    expect(fields["Check Box3"]).to eq ""
    expect(fields["Check Box4"]).to eq ""
    expect(fields["Check Box5"]).to eq ""
    expect(fields["Check Box7"]).to eq "Yes"
    expect(fields["PROSECUTING ATTORNEY REQUEST FOR DISMISSAL AND SEALING"]).to eq "11359(a)"
    expect(fields["Date"]).to eq "1999-10-01"
  end
end
