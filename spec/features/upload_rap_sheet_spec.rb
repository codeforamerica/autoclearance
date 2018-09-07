require 'rails_helper'

feature 'uploading rap sheets' do
  scenario 'user uploads a few rap sheets' do
    visit root_path
    expect(page).to have_content 'Upload RAP sheets'

    attach_file 'Select files', Rails.root.join('spec', 'fixtures', 'chewbacca_rap_sheet.pdf')
  end
end
