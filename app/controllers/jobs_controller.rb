class JobsController < ApplicationController
  def create
    ProcessRapSheetsJob.perform_later
  end
end
