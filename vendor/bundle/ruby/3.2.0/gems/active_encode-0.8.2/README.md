# ActiveEncode

Code: [![Version](https://badge.fury.io/rb/active_encode.png)](http://badge.fury.io/rb/active_encode)
[![Build Status](https://travis-ci.org/samvera-labs/active_encode.png?branch=master)](https://travis-ci.org/samvera-labs/active_encode)
[![Coverage Status](https://coveralls.io/repos/github/samvera-labs/active_encode/badge.svg?branch=master)](https://coveralls.io/github/samvera-labs/active_encode?branch=master)

Docs: [![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE)

Jump in: [![Slack Status](http://slack.samvera.org/badge.svg)](http://slack.samvera.org/)

# What is ActiveEncode?

ActiveEncode serves as the basis for the interface between a Ruby (Rails) application and a provider of encoding services such as [FFmpeg](https://www.ffmpeg.org/), [Amazon Elastic Transcoder](http://aws.amazon.com/elastictranscoder/), and [Zencoder](http://zencoder.com).

# Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_encode'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_encode

## Prerequisites

FFmpeg (tested with version 4+) and mediainfo (version 17.10+) need to be installed to use the FFmpeg engine adapter.

## Usage

Set the engine adapter (default: test), configure it (if neccessary), then submit encoding jobs!

```ruby
ActiveEncode::Base.engine_adapter = :ffmpeg
file = "file://#{File.absolute_path "spec/fixtures/fireworks.mp4"}"
ActiveEncode::Base.create(file, { outputs: [{ label: "low", ffmpeg_opt: "-s 640x480", extension: "mp4"}, { label: "high", ffmpeg_opt: "-s 1280x720", extension: "mp4"}] })
```
Create returns an encoding job that has been submitted to the adapter for processing.  At this point it will have an id, a state, the input, and any additional information the adapter returns.

```ruby
#<ActiveEncode::Base:0x007f8ef3b2ae88 @input=#<ActiveEncode::Input:0x007f8ef3b23188 @url="file:///Users/cjcolvar/Documents/Code/samvera-labs/active_encode/spec/fixtures/fireworks.mp4", @width=960.0, @height=540.0, @frame_rate=29.671, @duration=6024, @file_size=1629578, @audio_codec="mp4a-40-2", @video_codec="avc1", @audio_bitrate=69737, @video_bitrate=2092780, @created_at=2018-12-03 14:22:05 -0500, @updated_at=2018-12-03 14:22:05 -0500, @id=7653>, @options={:outputs=>[{:label=>"low", :ffmpeg_opt=>"-s 640x480", :extension=>"mp4"}, {:label=>"high", :ffmpeg_opt=>"-s 1280x720", :extension=>"mp4"}]}, @id="1e4a907a-ccff-494f-ad70-b1c5072c2465", @created_at=2018-12-03 14:22:05 -0500, @updated_at=2018-12-03 14:22:05 -0500, @current_operations=[], @output=[], @state=:running, @percent_complete=1, @errors=[]>
```
```ruby
encode.id  # "1e4a907a-ccff-494f-ad70-b1c5072c2465"
encode.state  # :running
```

This encode can be looked back up later using #find.  Alternatively, use #reload to refresh an instance with the latest information from the adapter:

```ruby
encode = ActiveEncode::Base.find("1e4a907a-ccff-494f-ad70-b1c5072c2465")
encode.reload
```

Progress of a running encode is shown with current operations (multiple are possible when outputs are generated in parallel) and percent complete.  Technical metadata about the input file may be added by the adapter.  This should include a mime type, checksum, duration, and basic technical details of the audio and video content of the file (codec, audio channels, bitrate, frame rate, and dimensions).  Outputs are added once they are created and should include the same technical metadata along with an id, label, and url.

If you want to stop the encoding job call cancel:

```ruby
encode.cancel!
encode.cancelled?  # true
```

An encoding job is meant to be the record of the work of the encoding engine and not the current state of the outputs.  Therefore moved or deleted outputs will not be reflected in the encoding job.

### AWS ElasticTranscoder

To use active_encode with the AWS ElasticTransoder, the following are required:
- An S3 bucket to store master files
- An S3 bucket to store derivatives (recommended to be separate)
- An ElasticTranscoder pipeline
- Some transcoding presets for the pipeline

Set the adapter:

```ruby
ActiveEncode::Base.engine_adapter = :elastic_transcoder
```

Construct the options hash:

```ruby
outputs = [{ key: "quality-low/hls/fireworks", preset_id: '1494429796844-aza6zh', segment_duration: '2' },
           { key: "quality-medium/hls/fireworks", preset_id: '1494429797061-kvg9ki', segment_duration: '2' },
           { key: "quality-high/hls/fireworks", preset_id: '1494429797265-9xi831', segment_duration: '2' }]
options = {pipeline_id: 'my-pipeline-id', masterfile_bucket: 'my-master-files', outputs: outputs}
```

Create the job:

```ruby
file = 'file:///path/to/file/fireworks.mp4' # or 's3://my-bucket/fireworks.mp4'
encode = ActiveEncode::Base.create(file, options)
```

### Custom jobs

Subclass ActiveEncode::Base to add custom callbacks or default options.  Available callbacks are before, after, and around the create and cancel actions.

```ruby
class CustomEncode < ActiveEncode::Base
  after_create do
    logger.info "Created encode with id #{self.reload.id}"
  end

  def self.default_options(input)
    {preset: 'avalon-skip-transcoding'}
  end
end
```

### Engine Adapters

Engine adapters are shims between ActiveEncode and the back end encoding service.  You can add an additional engine by creating an engine adapter class that implements `:create`, `:find`, and `:cancel` and passes the shared specs.

For example:
```ruby
# In your application at:
# lib/active_encode/engine_adapters/my_custom_adapter.rb
module ActiveEncode
  module EngineAdapters
    class MyCustomAdapter
      def create(input_url, options = {})
        # Start a new encoding job. This may be an external service, or a
        # locally queued job.

        # Return an instance ActiveEncode::Base (or subclass) that represents
        # the encoding job that was just started.        
      end

      def find(id, opts = {})
        # Find the encoding job for the given parameters.

        # Return an instance of ActiveEncode::Base (or subclass) that represents
        # the found encoding job.
      end

      def cancel(id)
        # Cancel the encoding job for the given id.

        # Return an instance of ActiveEncode::Base (or subclass) that represents
        # the canceled job.
      end
    end
  end
end
```
Then, use the shared specs...
```ruby
# In your application at...
# spec/lib/active_encode/engine_adapters/my_custom_adapter_spec.rb
require 'spec_helper'
require 'active_encode/spec/shared_specs'
RSpec.describe MyCustomAdapter do
  let(:created_job) {
    # an instance of ActiveEncode::Base represented a newly created encode job
  }
  let(:running_job) {
    # an instance of ActiveEncode::Base represented a running encode job
  }
  let(:canceled_job) {
    # an instance of ActiveEncode::Base represented a canceled encode job
  }
  let(:completed_job) {
    # an instance of ActiveEncode::Base represented a completed encode job
  }
  let(:failed_job) {
    # an instance of ActiveEncode::Base represented a failed encode job
  }
  let(:completed_tech_metadata) {
    # a hash representing completed technical metadata
  }
  let(:completed_output) {
    # data representing completed output
  }
  let(:failed_tech_metadata) {
    # a hash representing failed technical metadata
  }

  # Run the shared specs.
  it_behaves_like 'an ActiveEncode::EngineAdapter'
end
```

# Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)
