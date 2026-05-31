module Openseadragon
  module OpenseadragonHelper
    ##
    # Generate a <picture> tag containing the given sources.
    # A source can be a simple string, or a hash with the key
    # for the value of the src attribute and the value as the
    # arguments for the tag options.
    #
    # The last hash is intepreted as optional arguments for the 
    # <picture> tag. The second to last hash is optional arguments
    # to all <source> tags.
    #
    # @param sources [Array<String>, Array<Hash>]
    # @param source_tag_options [Hash]
    # @param picture_tag_options [Hash]
    def picture_tag *sources
      picture_options = sources.extract_options!.symbolize_keys
      source_options = sources.extract_options!.symbolize_keys
      sources.flatten!
      content_tag :picture, picture_options do
        safe_join(sources.map do |source|
          tag_options =  if source.is_a? Hash
            src, src_options = source.first
            src_options ||= {}
            source_options.merge(src_options.merge(src: src))
          else  
            source_options.merge(src: source)
          end
          
          yield tag_options if block_given?
          tag :source, tag_options
        end)
      end
    end

    ##
    # Generate a <picture> tag ready to be parsed by the openseadragon/rails 
    # javascript and transformed into an openseadragon viewer. Openseadragon
    # tile source options are passed as a JSON encoded hash on the
    # data-openseadragon attribute.
    #
    # @see [#picture_tag]
    # @param sources [Array<String>, Array<Hash>]
    # @param source_tag_options [Hash]
    # @param picture_tag_options [Hash]
    def openseadragon_picture_tag(*sources)
      picture_options = sources.extract_options!.symbolize_keys
      source_options = sources.extract_options!.symbolize_keys
      sources.flatten!

      tile_sources = sources.map { |thing| extract_openseadragon_picture_tilesource(thing) }
      
      picture_options[:data] ||= {}
      picture_options[:data][:openseadragon] = osd_asset_defaults.merge(picture_options[:data][:openseadragon] || {}).to_json

      picture_tag [tile_sources], { media: 'openseadragon' }.merge(source_options), picture_options
    end

    private

    ##
    # @overload extract_openseadragon_picture_tilesource(url)
    #   @param url [String]
    # @overload extract_openseadragon_picture_tilesource(tilesource_obj)
    #   @param tilesource_obj [#to_tilesource] a tilesource-backed object that
    #     is either a hash of openseadragon tilesource parameters or a URL to
    #     a manifest containing those parameters. 
    # @overload extract_openseadragon_picture_tilesource(options)
    #   @param [Hash] options a hash of openseadragon tilesource options
    #   @option options [Hash] :html parameters for the <source> tag
    # @overload extract_openseadragon_picture_tilesource(hash_with_tilesource)
    #   @param hash_with_tilesource [Hash<#to_tilesource, Hash>] the key of the hash
    #     is a tilesource object, and the options will be merged with the given hash
    #   @param [Hash] options a hash of openseadragon tilesource options, which will
    #      override the tilesource options
    #   @option options [Hash] :html parameters for the the <source> tag
    def extract_openseadragon_picture_tilesource thing
      if thing.respond_to? :to_tilesource
        html_options ||= {}
        html_options[:data] ||= {}
        html_options[:data][:openseadragon] ||= {}
        
        tilesource = thing.to_tilesource
        src = "openseadragon-tilesource"
        
        if tilesource.is_a? Hash
          html_options[:data][:openseadragon].merge! tilesource
        else
          src = tilesource
        end

        [src => html_options ]
      elsif thing.is_a? Hash
        src, src_options = thing.first

        html_options = {}
        html_options.merge! src_options.fetch(:html, {})
        html_options[:data] ||= {}
        
        osd_options = html_options[:data][:openseadragon] || {}
        osd_options.merge!(src_options.except(:html))

        if src.respond_to? :to_tilesource
          tilesource = src.to_tilesource
          
          if tilesource.is_a? Hash
            osd_options.reverse_merge! tilesource
            src = "openseadragon-tilesource"
          else
            src = tilesource
          end
        end
        
        html_options[:data][:openseadragon] = osd_options.to_json
        
        [ html_options.fetch(:src, src) => html_options ]
      else # string
        thing
      end
    end

    def osd_asset_defaults
      {
        prefixUrl: '',
        navImages: {
          zoomIn: {
            REST:     path_to_image('openseadragon/zoomin_rest.png'),
            GROUP:    path_to_image('openseadragon/zoomin_grouphover.png'),
            HOVER:    path_to_image('openseadragon/zoomin_hover.png'),
            DOWN:     path_to_image('openseadragon/zoomin_pressed.png')
          },
          zoomOut: {
              REST:   path_to_image('openseadragon/zoomout_rest.png'),
              GROUP:  path_to_image('openseadragon/zoomout_grouphover.png'),
              HOVER:  path_to_image('openseadragon/zoomout_hover.png'),
              DOWN:   path_to_image('openseadragon/zoomout_pressed.png')
          },
          home: {
              REST:   path_to_image('openseadragon/home_rest.png'),
              GROUP:  path_to_image('openseadragon/home_grouphover.png'),
              HOVER:  path_to_image('openseadragon/home_hover.png'),
              DOWN:   path_to_image('openseadragon/home_pressed.png')
          },
          fullpage: {
              REST:   path_to_image('openseadragon/fullpage_rest.png'),
              GROUP:  path_to_image('openseadragon/fullpage_grouphover.png'),
              HOVER:  path_to_image('openseadragon/fullpage_hover.png'),
              DOWN:   path_to_image('openseadragon/fullpage_pressed.png')
          },
          rotateleft: {
              REST:   path_to_image('openseadragon/rotateleft_rest.png'),
              GROUP:  path_to_image('openseadragon/rotateleft_grouphover.png'),
              HOVER:  path_to_image('openseadragon/rotateleft_hover.png'),
              DOWN:   path_to_image('openseadragon/rotateleft_pressed.png')
          },
          rotateright: {
              REST:   path_to_image('openseadragon/rotateright_rest.png'),
              GROUP:  path_to_image('openseadragon/rotateright_grouphover.png'),
              HOVER:  path_to_image('openseadragon/rotateright_hover.png'),
              DOWN:   path_to_image('openseadragon/rotateright_pressed.png')
          },
          previous: {
              REST:   path_to_image('openseadragon/previous_rest.png'),
              GROUP:  path_to_image('openseadragon/previous_grouphover.png'),
              HOVER:  path_to_image('openseadragon/previous_hover.png'),
              DOWN:   path_to_image('openseadragon/previous_pressed.png')
          },
          next: {
              REST:   path_to_image('openseadragon/next_rest.png'),
              GROUP:  path_to_image('openseadragon/next_grouphover.png'),
              HOVER:  path_to_image('openseadragon/next_hover.png'),
              DOWN:   path_to_image('openseadragon/next_pressed.png')
          }
        }
      }.with_indifferent_access
    end

  end
end
