class JobsController < ApplicationController
  protect_from_forgery with: :exception

  def create
    ProcessRapSheetsJob.perform_later(Counties::SAN_FRANCISCO)
  end
end
