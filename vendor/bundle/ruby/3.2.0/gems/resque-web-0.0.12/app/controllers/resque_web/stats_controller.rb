module ResqueWeb
  class StatsController < ResqueWeb::ApplicationController
    subtabs :resque, :redis, :keys

    def index
      redirect_to action: "resque"
    end

    def resque
      respond_to do |format|
        format.html
        format.json { render json: Hash[Resque.info.sort] }
      end
    end

    def redis
      respond_to do |format|
        format.html
        format.json { render json: Hash[Resque.redis.redis.info.sort] }
      end
    end

    def keys
      respond_to do |format|
        format.html do
          if params[:id]
            render 'key'
          else
            render 'keys'
          end
        end
        format.json { render json: Resque.keys.sort }
      end
    end
  end
end
