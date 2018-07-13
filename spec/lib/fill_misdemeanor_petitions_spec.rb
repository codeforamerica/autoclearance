require 'spec_helper'
require 'csv'
require 'pdf-forms'
require_relative '../../app/lib/fill_misdemeanor_petitions'

describe FillMisdemeanorPetitions do
  it 'populates motions per row' do
    file = "./misdemeanors.csv"
    output_dir = "./motions"
    described_class.new(path: file, output_dir: output_dir).fill
    
    expect(Dir["#{output_dir}/*"].length).to eq 3    
  end
end
