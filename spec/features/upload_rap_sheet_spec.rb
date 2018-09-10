require 'rails_helper'

feature 'uploading rap sheets' do
  scenario 'user uploads a few rap sheets', js: true do
    visit root_path
    expect(page).to have_content 'Upload RAP sheets'

    files = [Rails.root.join('spec', 'fixtures', 'chewbacca_rap_sheet.pdf'), Rails.root.join('spec', 'fixtures', 'skywalker_rap_sheet.pdf')]

    attach_file 'Select files', files, multiple: true, visible: false

    expect(page).to have_content 'chewbacca_rap_sheet.pdf'
    expect(page).to have_content 'skywalker_rap_sheet.pdf'
  end
end
