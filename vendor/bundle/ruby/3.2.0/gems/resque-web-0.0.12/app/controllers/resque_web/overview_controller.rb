module ResqueWeb
  class OverviewController < ResqueWeb::ApplicationController
    def show
      render :layout => !request.xhr?, :locals => { :polling => request.xhr? }
    end
  end
end
