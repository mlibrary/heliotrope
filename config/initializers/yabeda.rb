# frozen_string_literal: true

Yabeda.configure do
  # Define a histogram for download durations with specified buckets for timing
  Yabeda.histogram :fedora_file_download_duration, comment: "Time taken to download a file from fedora", unit: :seconds do
    # buckets [0.5, 1, 2, 5, 10, 30, 60, 120] # Adjust buckets based on expected download durations
    buckets [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30, 60, 120]
    tags %i[status]
  end
end
