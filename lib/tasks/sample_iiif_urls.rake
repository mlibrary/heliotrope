# frozen_string_literal: true

desc "Generate riif image-service urls based off of random FileSets that are tiffs. Used to stress test with siege."
task sample_iiif_urls: :environment do
  #
  # Run this script in the environment you want to test:
  #
  # $ RAILS_ENV=production bundle exec rake sample_iiif_urls > ~/urls.txt
  #
  # Then run siege (not installed on library machines) to stress test the riiif gem:
  #
  # siege -f ~/urls.txt -i -c 3 -b -t180S
  #
  # -f "file" use this file of urls
  # -i "internet", behave like internet users would (things like randomly sampling the links in ~/urls.txt)
  # -c "concurrent", 3 concurrent users
  # -b "benchmark", no delays between requests
  # -t "time" do it for 180 seconds
  #

  tiffs = FileSet.all.to_a.select do |f|
    f.original_file.mime_type.match(/tiff/)
  end

  # Use at most 20 tiffs to generate urls
  ids = tiffs.sample(tiffs.length > 20 ? 20 : tiffs.length).map(&:id)

  urls = []

  ids.each do |id|
    image = Riiif::Image.new(id)
    info = image.info
    # Get 100 different tiles for each tiff
    100.times do
      x, y, w, h = random_region(info)
      urls << "#{Rails.application.routes.url_helpers.root_url}/image-service/#{id}/#{x},#{y},#{w},#{h}/full/0/default.jpg"
    end
  end

  puts urls
end

def random_region(info)
  width = info[:width]
  height = info[:height]

  x = rand(width)
  y = rand(height)

  w = width - x
  h = height - y

  [x, y, w, h]
end
