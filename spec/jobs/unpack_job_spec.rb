# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnpackJob, type: :job do
  describe "perform" do
    context "with an epub" do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }

      it "unzips the epub and creates the database" do
        described_class.perform_now(epub.id, 'epub')
        @root_path = Hyrax::DerivativePath.new(epub.id).derivative_path + 'epub'
        expect(File.exist?(File.join(@root_path, epub.id + '.db'))).to be true
      end
    end

    context "with a webgl" do
      let(:webgl) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.zip'))) }

      it "unzips the webgl" do
        described_class.perform_now(webgl.id, 'webgl')
        @root_path = Hyrax::DerivativePath.new(webgl.id).derivative_path + 'webgl'
        expect(File.exist?(File.join(@root_path, "Build", "UnityLoader.js"))).to be true
      end
    end
  end
end
