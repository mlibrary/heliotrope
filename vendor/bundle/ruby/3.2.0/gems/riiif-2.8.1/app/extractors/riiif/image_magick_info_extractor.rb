module Riiif
  # Get information using imagemagick to interrogate the file
  class ImageMagickInfoExtractor < AbstractInfoExtractor
    # perhaps you want to use GraphicsMagick instead, set to "gm identify"
    self.external_command = 'identify'

    def extract
      height, width, format, channels = Riiif::CommandRunner.execute(
        "#{external_command} -format '%h %w %m %[channels]' '#{@path}[0]'"
      ).split(' ')

      {
        height: Integer(height),
        width: Integer(width),
        format: format,
        channels: channels
      }
    end
  end
end
