class JobsController < ApplicationController
  def create
    RapSheetProcessor.run
  end
end
