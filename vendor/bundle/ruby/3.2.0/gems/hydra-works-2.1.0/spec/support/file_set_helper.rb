module FileSetHelper
  # Mocking out the Hydra::Works::FileSet sufficiently to add original_file
  # without a save to fedora. This works by mocking the response from ldp_source.head
  # so AF association believes subject is already saved.
  def mock_add_file_to_file_set(fs, file)
    allow(fs.ldp_source).to receive(:head).and_return(Faraday::Response.new)
    allow(file).to receive(:has_content?).and_return(true)
    fs.original_file = file
  end

  RSpec.configure do |config|
    config.include FileSetHelper
  end
end
