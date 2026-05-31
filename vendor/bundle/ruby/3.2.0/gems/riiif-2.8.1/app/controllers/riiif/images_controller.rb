module Riiif
  class ImagesController < ::ApplicationController
    before_action :link_header, only: [:show, :info]

    rescue_from IIIF::Image::InvalidAttributeError do
      head :bad_request
    end

    def show
      begin
        image = model.new(image_id)
        status = if authorization_service.can?(:show, image)
                   :ok
                 else
                   :unauthorized
                 end
      rescue ImageNotFoundError
        status = :not_found
      end

      image = error_image(status) unless status == :ok

      data = image.render(image_request_params)
      headers['Access-Control-Allow-Origin'] = '*'
      # Set a Cache-Control header
      expires_in cache_expires, public: public_cache? if status == :ok
      send_data data,
                status: status,
                type: Mime::Type.lookup_by_extension(params[:format]),
                disposition: 'inline'
    end

    def info
      image = model.new(image_id)
      if authorization_service.can?(:info, image)
        image_info = image.info
        return render json: { error: 'no info' }, status: :not_found unless image_info.valid?
        headers['Access-Control-Allow-Origin'] = '*'
        # Set a Cache-Control header
        expires_in cache_expires, public: public_cache?
        render json: image_info.to_h.merge(server_info), content_type: 'application/ld+json'
      else
        render json: { error: 'unauthorized' }, status: :unauthorized
      end
    end

    # See https://fetch.spec.whatwg.org/#http-access-control-allow-headers
    def info_options
      response.headers['Access-Control-Allow-Headers'] = 'Authorization'
      self.response_body = ''
    end

    # this is a workaround for https://github.com/rails/rails/issues/25087
    def redirect
      # This was attempted with just info_path, but it gave a NoMethodError
      redirect_to riiif.info_path(params[:id])
    end

    protected

      LEVEL1 = 'http://iiif.io/api/image/2/level1.json'.freeze

      # @return seconds before the request expires. Defaults to 1 year.
      def cache_expires
        1.year
      end

      # Should the Cache-Control header be public? Override this if you want to have a
      # public Cache-Control set.
      # @return FalseClass
      def public_cache?
        false
      end

      def model
        params.fetch(:model, 'riiif/image').camelize.constantize
      end

      def image_id
        params[:id]
      end

      ##
      # @return [ActiveSupport::HashWithIndifferentAccess]
      def image_request_params
        result = params.permit(:region, :size, :rotation, :quality, :format, :model, :id).to_h
        return result.with_indifferent_access if Rails.version < '5'
        result.except(:model, :id)
      end

      def authorization_service
        model.authorization_service.new(self)
      end

      def link_header
        response.headers['Link'] = "<#{LEVEL1}>;rel=\"profile\""
      end

      # @param [Symbol] err E.g., :not_found, :unauthorized
      # @return [Image]
      def error_image(err)
        # rubocop:disable Lint/HandleExceptions
        begin
          image = Riiif.send("#{err}_image")
        rescue NoMethodError
        end
        # rubocop:enable Lint/HandleExceptions

        if image.nil?
          raise ImageNotFoundError,
                "Riiif.#{err}_image is not configured; assign it to an image path in your RIIIF initializer"
        end

        model.new(image_id, Riiif::File.new(image))
      end

      CONTEXT = '@context'.freeze
      CONTEXT_URI = 'http://iiif.io/api/image/2/context.json'.freeze
      ID = '@id'.freeze
      PROTOCOL = 'protocol'.freeze
      PROTOCOL_URI = 'http://iiif.io/api/image'.freeze
      PROFILE = 'profile'.freeze

      def server_info
        {
          CONTEXT => CONTEXT_URI,
          ID => request.original_url.sub('/info.json', ''),
          PROTOCOL => PROTOCOL_URI,
          PROFILE => [LEVEL1, 'formats' => IIIF::Image::OptionDecoder::OUTPUT_FORMATS]
        }
      end
  end
end
