# hydra-derivatives

Code:
[![Version](https://badge.fury.io/rb/hydra-derivatives.png)](http://badge.fury.io/rb/hydra-derivatives)
[![Build Status](https://circleci.com/gh/samvera/hydra-derivatives.svg?style=svg)](https://circleci.com/gh/samvera/hydra-derivatives)
[![Coverage Status](https://coveralls.io/repos/github/samvera/hydra-derivatives/badge.svg?branch=main)](https://coveralls.io/github/samvera/hydra-derivatives?branch=main)

Docs:
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE.txt)

Community Support: [![Samvera Community Slack](https://img.shields.io/badge/samvera-slack-blueviolet)](http://slack.samvera.org/)

# What is hydra-derivatives?

Derivative generation for Samvera applications.

## Product Owner & Maintenance

`hydra-derivatives` is a Core Component of the Samvera Community. The documentation for what this means can be found [here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).

### Product Owner

[stkenny](https://github.com/stkenny)

# Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

# Getting Started

If you have an ActiveFedora class like this:
```ruby
    class GenericFile < ActiveFedora::Base
        include Hydra::Derivatives

        contains 'content'
        attr_accessor :mime_type

        # Use a block to declare which derivatives you want to generate

        def create_derivatives(filename)
          case mime_type
          when 'application/pdf'
            PdfDerivatives.create(filename, outputs: [{ label: :thumb, size: "100x100>" }]
          when 'audio/wav'
            AudioDerivatives.create(self, source: :original_file, outputs: [{ label: :mp3, format: 'mp3', url: "#{uri}/mp3" }, { label: :ogg, format: 'ogg', url: "#{uri}/ogg" }])
          when 'video/avi'
            VideoDerivatives.create(filename, outputs: [{ label: :mp4, format: 'mp4'}, { label: :webm, format: 'webm'}])
          when 'image/png', 'image/jpg'
            ImageDerivatives.create(self, source: :original_file,
                                    outputs: [
                                      { label: :medium, size: "300x300>", url: "#{uri}/medium" },
                                      { label: :thumb, size: "100x100>", url: "#{uri}/thumb" }])
          when 'application/vnd.ms-powerpoint'
            DocumentDerivatives.create(filename, outputs[{ label: :preservation, format: 'pptx' }, { label: :access, format: 'pdf' }, { label: :thumnail, format: 'jpg' })
          when 'image/tiff'
            Jpeg2kDerivatives.create(filename, outputs: [{ label: :service, resize: "3600x3600>" }])
          end
        end
    end
```

And you add some content to it:

```ruby
   obj = GenericFile.new
   obj.original_file.content = File.open(...)
   obj.mime_type = 'image/jpg'
   obj.save
```

Then when you call `obj.create_derivatives` two new files, 'thumbnail' and 'content_medium', will have been created with downsized images in them.

We recommend you run `obj.create_derivatives` in a background worker, because some derivative creation (especially videos) can take a long time.

The ActiveEncode runner provides support for using external video transcoding services like Amazon Elastic Transcoder.  See [ActiveEncode](https://github.com/samvera-labs/active_encode) for details on specific adapters supported.

## Configuration

### Retrieving from a basic container in Fedora

Provide the object and `:source` option instead of a filename

```ruby
PdfDerivatives.create(active_fedora_object, source: :original_file, outputs: [{ label: :thumb, size: "100x100>" }]
```

### Processing Timeouts

hydra-derivatives can be configured to timeout derivatives processes.  Each process type has a separate timeout.
If no timeout is set the system will process until complete (possibly indefinitely).

```
require 'hydra/derivatives'

Hydra::Derivatives::Processors::Video::Processor.timeout  = 10.minutes
Hydra::Derivatives::Processors::Document.timeout = 5.minutes
Hydra::Derivatives::Processors::Audio.timeout = 10.minutes
Hydra::Derivatives::Processors::Image.timeout = 5.minutes
Hydra::Derivatives::Processors::ActiveEncode.timeout = 5.minutes

```

You can add this to a `config/initializers/` file ([see Scholarsphere as an example](https://github.com/psu-stewardship/scholarsphere/blob/e16586c4bf6f7aed652924acc47dbe4ec774ff00/config/initializers/hydra_derivatives_config.rb#L5)). Another possibility, though unverified, is that you may try adding it to your `config/application.rb` or even vary by environments (e.g. `config/environments/test.rb`).

### Video Processing configuration

Flags can be set for using different video codes.  Default codecs are shown below

```
Hydra::Derivatives::Processors::Video::Processor.config.mpeg4.codec = '-vcodec libx264 -acodec libfdk_aac'
Hydra::Derivatives::Processors::Video::Processor.config.webm.codec = '-vcodec libvpx -acodec libvorbis'
Hydra::Derivatives::Processors::Video::Processor.config.mkv.codec = '-vcodec ffv1'
Hydra::Derivatives::Processors::Video::Processor.config.jpeg.codec = '-vcodec mjpeg'
```

### Configuration for Audio/Video Processing with ActiveEncode

```ruby
# Set the transcoding engine
ActiveEncode::Base.engine_adapter = :elastic_transcoder

# Sleep time (in seconds) to poll for status of encoding job
Hydra::Derivatives.active_encode_poll_time = 10

# If you want to use a different class for the source file service
Hydra::Derivatives::ActiveEncodeDerivatives.source_file_service = MyCustomSourceFileService

# If you want to use a different class for the output file service
Hydra::Derivatives::ActiveEncodeDerivatives.output_file_service = MyCustomOutputFileService
```

Note: Please don't confuse these methods with the similar methods in the parent class:
`Hydra::Derivatives.source_file_service` and `Hydra::Derivatives.output_file_service`

For additional documentation on using ActiveEncode, see:
* [Using Amazon Elastic Transcoder](doc/amazon_elastic_transcoder.md)

### Additional Directives

#### Layers

When processing pdf files or images that may contain layers, you can select which layer you want
to use. This is especially useful with multipage pdf files, which are flattened to ensure the
background is correctly rendered. By default, the first page, or layer 0, is chosen when creating
images from pdf files. If you want to choose a different page, such as the second page, you can
set the layer directive:

```
PdfDerivatives.create(filename, outputs: [{ label: :thumb, size: "100x100>", layer: 1 }]
```

# Installation

Just add `gem 'hydra-derivatives'` to your Gemfile.

## Dependencies

* [FITS](http://fitstool.org/) - 1.0.x (1.0.5 is known to be good)
* [FFMpeg](http://www.ffmpeg.org/)
* [LibreOffice](https://www.libreoffice.org/) (openoffice.org-headless on Ubuntu/Debian to avoid "_X11 error: Can't open display:_")
* [GhostScript](https://www.ghostscript.com/)
* [ImageMagick](http://www.imagemagick.org/)
* Kakadu's [kdu_compress](http://www.kakadusoftware.com/) (optional)
* [ufraw](http://ufraw.sourceforge.net/) or [dcraw](https://dechifro.org/dcraw/)

To enable LibreOffice, FFMpeg, ImageMagick, FITS support, and kdu_compress support, make sure they are on your path. Most people will put that in their .bash_profile or somewhere similar.

For example:

```bash
# in .bash_profile
export PATH=${PATH}:/Users/justin/workspace/fits-1.0.5:/Applications/LibreOffice.app/Contents/MacOS
```

Alternatively, you can configure their paths:
```ruby
Hydra::Derivatives.ffmpeg_path = '/opt/local/ffmpeg/bin/ffmpeg'
Hydra::Derivatives.fits_path = '/opt/local/fits/bin/fits.sh'
Hydra::Derivatives.libreoffice_path = '/opt/local/libreoffice_path/bin/soffice'
Hydra::Derivatives.kdu_compress_path = '/usr/local/bin/kdu_compress'
```
## Configuration

ImageMagick by default stores temp files in system /tmp. If you'd like to override this, adjust these environment variables:

```
MAGICK_TEMPORARY_PATH
MAGICK_TMPDIR
MAGICK_TEMPDIR

```
YMMV as to where setting them will take effect in your app; the application's web server's vhost directives are a location known to work with an Apache web server set up.

ImageMagick by default disables reading and writing of PDFs due to a [vulnerability in ghostscript](https://www.kb.cert.org/vuls/id/332928/). Make sure to install a fixed version of ghostscript and modify ImageMagick's security policy to allow reading and writing PDFs:
```
sudo sed -i 's/policy domain="coder" rights="none" pattern="PDF"/policy domain="coder" rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml
```

## JPEG2k Directives

Unlike the other processors, the `Jpeg2kImage` processor does not generally accept arguments that directly (or nearly so) translate to the arguments you would give to the corresponding command line utility.

Instead, each directive may contain these arguments:

  * `:output_path` (String) : The name for the new file
  * `:to_srgb` (Boolean) : If `true` and the image is a color image it will map the source image color profile to sRGB. Default: `true`
  * `:resize` (String) : Geometry; the same syntax as the `Hydra::Derivatives::Image` processor
  * `:recipe` :
    - If a Symbol the recipe will be read from the `Hydra::Derivatives.kdu_compress_recipes` hash. You can override this, or a couple of samples are supplied. The symbol in the config file should be the name in the model + `_{quality}`, e.g. `recipe: :default` will look `:default_color` or `:default_gray` in the hash.
    - If a String the recipe in the string will be used. You may include anything the command line utility will accept except `-i` or `-o`. See `$ kdu_compress -usage` in your shell.
    - If no `:recipe` is provided the processor will examine the image and make a best guess, but you can set a few basic options (the remainder of this list). Note that these are ignored if you provided a recipe via either of the first two methods described.
  * `:levels` (Integer) : The number of decomposition levels. The default is the number of times the long dimension can be divided by two, down to 96, e.g. a 7200 pixel image would have 6 levels (3600, 1800, 900, 450, 225, 112)
  * `:layers` (Integer) : The number of quality layers. Default: 8
  * `:compression` (Integer) : The left number of the compression ratio `n:1`, e.g. 12 will apply 12:1 compression. Default: 10.
  * `:tile_size` (Integer) : Pixel dimension of the tiles. Default: 1024

# Development Environment

## Dependencies

* [ImageMagick](https://www.imagemagick.org)
    * On a mac, do `brew install imagemagick`
* [LibreOffice](https://www.libreoffice.org/)
*   * On a mac, do `brew install libreoffice --cask`
* [Kakadu](http://kakadusoftware.com/)
    * On a mac, extract the file and run the pkg installer therein (don't get distracted by the files called kdu_show)
* [Ghostscript](https://www.ghostscript.com/)
    * On a mac, `brew install ghostscript`
* ufraw
    * On a mac, `brew install ufraw`
* dcraw (ufraw alternative)
    * On a mac, `brew install dcraw`
    * You will need to modify ImageMagick's delegate for dng files in order to use dcraw.
	* First find where the deletegates.xml file is located: `identify -list delegate | grep Path`
	* Edit the delegates.xml file by replacing the dng:decode delegate line with the following:
          ```<delegate decode="dng:decode" command="&quot;dcraw&quot; -c -q 3 -H 5 -w &quot;%i&quot; | &quot;convert&quot; - &quot;%u.png&quot;"/>```
* libvpx
    * On a mac, `brew install libvpx`
* ffmpeg
    * On a mac, `brew install ffmpeg`
    * Ensure `libvpx` is installed first

## Running Tests

1. Run tests with `RAILS_ENV=test bundle exec rake ci`

## Running specific tests

If you don't want to run the whole suite all at once like CI, do the following:

1. Run the test servers with `rake derivatives:test_server`
2. Run the tests.

# Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://samvera.org/wp-content/uploads/2017/06/samvera-logo-tm.svg)
