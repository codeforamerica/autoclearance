require 'rails_helper'

describe RapSheetProcessor do
  it 'moves rap sheets from input bucket to output bucket' do
    Dir.mkdir '/tmp/autoclearance-rap-sheet-inputs' unless Dir.exist? '/tmp/autoclearance-rap-sheet-inputs'
    Dir.mkdir '/tmp/autoclearance-outputs' unless Dir.exist? '/tmp/autoclearance-outputs'
    File.open("/tmp/autoclearance-rap-sheet-inputs/foo.txt", "w")
    
    described_class.run
    
    expect(Dir["/tmp/autoclearance-rap-sheet-inputs/foo.txt"]).to eq []
    expect(Dir["/tmp/autoclearance-outputs/foo.txt"]).to eq ["/tmp/autoclearance-outputs/foo.txt"]
  end
end
