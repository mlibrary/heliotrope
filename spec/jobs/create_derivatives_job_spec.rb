# frozen_string_literal: true

require 'rails_helper'

describe Hyrax::CreateDerivativesJob do
  let(:file_set) { create(:file_set) }

  before do
    file_set.original_file = file
    file_set.save!
  end

  context "with a tiff image" do
    let(:file) do
      Hydra::PCDM::File.new do |f|
        f.content = File.open(File.join(fixture_path, 'kitty.tif'))
        f.original_name = 'kitty.tif'
        f.mime_type = 'image/tiff'
      end
    end

    it "creates derivatives" do
      expect(Hydra::Derivatives::ImageDerivatives).to receive(:create)
      described_class.perform_now(file_set, file.id)
    end
  end

  # see config/initializers/file_set_derivative_service_monkey_patch.rb
  context "with a Word file" do
    let(:file) do
      Hydra::PCDM::File.new do |f|
        f.content = File.open(File.join(fixture_path, 'blah.docx'))
        f.original_name = 'blah.docx'
        f.mime_type = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      end
    end

    it "doesn't create derivatives" do
      expect(Hydra::Derivatives::DocumentDerivatives).to_not receive(:create)
      described_class.perform_now(file_set, file.id)
    end
  end

  # see config/initializers/file_set_derivative_service_monkey_patch.rb
  context "with an Excel file" do
    let(:file) do
      Hydra::PCDM::File.new do |f|
        f.content = File.open(File.join(fixture_path, 'stuff.xlsx'))
        f.original_name = 'stuff.xlsx'
        f.mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      end
    end

    it "doesn't create derivatives" do
      expect(Hydra::Derivatives::DocumentDerivatives).to_not receive(:create)
      described_class.perform_now(file_set, file.id)
    end
  end
end
