# frozen_string_literal: true

module API
  module V1
    # Monographs Controller
    class MonographsController < API::ApplicationController
      before_action :set_monograph, only: %i[show extract manifest]

      # @overload index
      #   List monographs
      #   @example
      #     get /api/monographs
      #   @return [ActionDispatch::Response] array of {Monograph}
      # @overload index
      #   List press monographs
      #   @example
      #     get /api/presses/:press_id/monographs
      #   @return [ActionDispatch::Response] array of {Monograph}
      #
      #     (See ./app/views/api/v1/monograph/index.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/monographs/index.json.jbuilder}
      #
      #     (See ./app/views/api/v1/monograph/_monograph.json.jbuilder)
      #
      #     {include:file:app/views/api/v1/monographs/_monograph.json.jbuilder}
      def index
        @monographs = if params[:press_id].present?
                        set_press
                        Monograph.where(press: @press.subdomain)
                      else
                        Monograph.all
                      end
      end

      # Get monograph by id
      # @example
      #   get /api/monograph/:id
      # @param [Hash] params { id: Number }
      # @return [ActionDispatch::Response] {Monograph}
      #
      #   (See ./app/views/api/v1/monograph/show.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/monographs/show.json.jbuilder}
      #
      #   (See ./app/views/api/v1/monograph/_monograph.json.jbuilder)
      #
      #   {include:file:app/views/api/v1/monographs/_monograph.json.jbuilder}
      def show; end

      # Get monograph manifest by id
      # @example
      #   get /api/monograph/:id/manifest
      # @param [Hash] params { id: String }
      # @return [ActionDispatch::Response] {zip file}
      def manifest
        return head :no_content unless ValidationService.valid_noid?(params['id'])
        noid = params['id']
        manifest_file = File.join(manifest_path, "#{noid}.csv")
        FileUtils.rm_rf(manifest_file) if File.exist?(manifest_file)
        file = File.open(manifest_file, 'wb')
        file.write(Export::Exporter.new(noid).export)
        file.close

        send_data File.read(manifest_file), type: 'text/csv', filename: manifest_file, dispostion: 'inline'
      end

      # Get monograph extract by id
      # @example
      #   get /api/monograph/:id/extract
      # @param [Hash] params { id: String }
      # @return [ActionDispatch::Response] {zip file}
      def extract
        return head :no_content unless ValidationService.valid_noid?(params['id'])
        noid = params['id']
        extract_dir = File.join(extract_path, noid)
        FileUtils.rm_rf(extract_dir) if Dir.exist?(extract_dir)
        FileUtils.mkdir(extract_dir)
        Export::Exporter.new(noid).extract(extract_dir, true)
        extract_zip = File.join(extract_path, "#{noid}.zip")
        FileUtils.rm_rf(extract_zip) if File.exist?(extract_zip)
        Zip::File.open(extract_zip, Zip::File::CREATE) do |zipfile|
          dir = Dir.new(extract_dir)
          dir.each do |entry|
            next if ['.', '..'].include?(entry)
            zipfile.add(entry, File.join(extract_dir, entry))
          end
        end
        FileUtils.rm_rf(extract_dir) if Dir.exist?(extract_dir)

        send_data File.read(extract_zip), type: 'application/zip', filename: extract_zip, dispostion: 'inline'
      end

      private

        def manifest_path
          return @manifest_path if @manifest_path.present?
          @manifest_path = Rails.root.join('tmp', 'export', 'manifest')
          FileUtils.mkdir_p(@manifest_path) unless Dir.exist?(@manifest_path)
          @manifest_path
        end

        def extract_path
          return @extract_path if @extract_path.present?
          @extract_path = Rails.root.join('tmp', 'export', 'extract')
          FileUtils.mkdir_p(@extract_path) unless Dir.exist?(@extract_path)
          @extract_path
        end

        def set_press
          @press = Press.find_by(subdomain: params[:press_id]) || Press.find(params[:press_id])
        end

        def set_monograph
          @monograph = Monograph.find(params[:id])
        end

        def monograph_params
          params.require(:monograph).permit(:identifier, :title)
        end
    end
  end
end
