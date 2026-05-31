require 'ruby-vips' if Riiif::Engine.config.use_vips

module Riiif
  # Get information using (lib)vips to interrogate the file
  class VipsInfoExtractor < AbstractInfoExtractor
    self.external_command = 'vipsheader'

    def extract
      attributes = Riiif::CommandRunner.execute("#{external_command} '#{@path}' -a")
                                       .split(/\n/)
                                       .map { |str| str.strip.split(': ', 2) }.to_h
      width, height = attributes.values_at("width", "height")

      {
        height: Integer(height),
        width: Integer(width),
        format: attributes["vips-loader"].match?("pngload") ? "PNG" : "JPEG",
        channels: ::Vips::Image.new_from_file(@path.to_s).has_alpha? ? "srgba" : "srgb"
      }
    end
  end
end
