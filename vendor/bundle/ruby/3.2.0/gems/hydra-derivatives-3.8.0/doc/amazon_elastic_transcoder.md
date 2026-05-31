# Create Audio and Video Derivatives using Amazon Elastic Transcoder

`hydra-derivatives` uses the
[active\_encode gem](https://github.com/projecthydra-labs/active_encode)
to allow you to use different encoding services.
These instructions are for Amazon's Elastic Transcoder service.

## Prerequsites

### Set up the Elastic Transcoder Pipeline

Set up a pipeline on AWS Elastic Transcoder that defines:

* input bucket
* bucket for transcoded files
* bucket for thumbnails

### Configure AWS credentials

Optional: If you don't want to pass these values in your ruby code using `Aws.config`, you can set environment variables instead:

* AWS\_ACCESS\_KEY\_ID
* AWS\_SECRET\_ACCESS\_KEY
* AWS\_REGION

### Install gems

Add to your `Gemfile`:

* aws-sdk

### Configure initializer

In an initializer file such as `config/initializers/active_encode.rb`, make sure you have the following code:

```ruby
# Use Amazon's Elastic Transcoder
ActiveEncode::Base.engine_adapter = :elastic_transcoder
```

## How to create derivatives (Multiple derivatives per Elastic Transcoder job)

```ruby
# Access config for AWS
Aws.config[:access_key_id] = 'put your access key here'
Aws.config[:secret_access_key] = 'put your secret key here'
Aws.config[:region] = 'us-east-1'

# The pipeline that I set up in Elastic Transcoder
pipeline_id = '1490715200916-25b08y'

# The file "sample_data.mp4" has already been uploaded to the input bucket for my pipeline.
input_file = 'sample_data.mp4'

# Choose a name for the output files
base_file_name = 'output_file_17'

# Settings for a low-res video derivative using a preset for a 320x240 resolution mp4 file
low_res_video = { key: "#{base_file_name}.mp4", preset_id: '1351620000001-000061' }

# Settings for a flash video derivative
flash_video = { key: "#{base_file_name}.flv", preset_id: '1351620000001-100210' }

# Settings to send to the Elastic Transcoder job
job_settings = { pipeline_id: pipeline_id, output_key_prefix: "active_encode-demo_app/", outputs: [low_res_video, flash_video] }

# Run the encoding
Hydra::Derivatives::ActiveEncodeDerivatives.create(input_file, outputs: [job_settings])

# Note: Your rails console will not return to the prompt until the encoding is complete,
# so it might sit there for several minutes with no feedback.
# Use the AWS console to see the current status of the encoding.
```

## How to create derivatives (One derivative per Elastic Transcoder job)

If you want to run a separate Elastic Transcoder job for each derivative file, you could do something like this:

```ruby
# Settings for a low-res video derivative using a preset for a 320x240 resolution mp4 file.
low_res_preset_id = '1351620000001-000061'
low_res_output_file = 'output_15.mp4'
low_res_video = { pipeline_id: pipeline_id, output_key_prefix: "active_encode-demo_app/", outputs: [{ key: low_res_output_file, preset_id: low_res_preset_id }] }

# Settings for a flash video derivative
flash_preset_id = '1351620000001-100210'
flash_output_file = 'output_15.flv'
flash_video = { pipeline_id: pipeline_id, output_key_prefix: "active_encode-demo_app/", outputs: [{ key: flash_output_file, preset_id: flash_preset_id }] }

Hydra::Derivatives::ActiveEncodeDerivatives.create(input_file, outputs: [low_res_video, flash_video])
```

## How to pass in a ruby object

If you want to pass in an `ActiveFedora::Base` object (or some other record) instead of just a String for the input file name, you need to set the `source` option to specify which method to call on your object to get the file name.  For example:

```ruby
# Some object that contains the source file name
class Video
  attr_accessor :source_file_name
end

video_record = Video.new
video_record.source_file_name = 'sample_data.mp4'

Hydra::Derivatives::ActiveEncodeDerivatives.create(video_record, source: :source_file_name, outputs: [low_res_video])
```

## How to pass in a custom encode class

If you don't want to use the default encode class `::ActiveEncode::Base`, you can pass in `encode_class`:

```ruby
Hydra::Derivatives::ActiveEncodeDerivatives.create(video_record, encode_class: MyCustomEncode, source: :source_file_name, outputs: [low_res_video])
```

