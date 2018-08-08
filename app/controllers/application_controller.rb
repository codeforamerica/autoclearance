class ApplicationController < ActionController::Base
  def not_found
    render :file => 'public/404.html', :status => :not_found, :layout => false
  end
end
