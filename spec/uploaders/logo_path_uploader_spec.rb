# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LogoPathUploader do
  let(:press) { create(:press, logo_path: Rack::Test::UploadedFile.new(fixture, Rack::Mime.mime_type(fixture.extname))) }
  let(:fixture) { Rails.root.join('spec', 'fixtures', 'csv', 'import', 'shipwreck.jpg') }

  before do
    stub_const('LogoPathUploader::DIMENSIONS_CACHE', ActiveSupport::Cache::MemoryStore.new)
  end

  after { press.logo_path.remove! }

  it 'reads existing uploads and caches dimensions across uploader instances' do
    expect(MiniMagick::Image).to receive(:new).with(press.logo_path.path).once.and_call_original

    expect(Press.find(press.id).logo_path.dimensions).to eq(width: 305, height: 240)
    expect(Press.find(press.id).logo_path.dimensions).to eq(width: 305, height: 240)
  end

  it 'uses the new dimensions when an upload is replaced' do
    expect(press.logo_path.dimensions).to eq(width: 305, height: 240)

    replacement = Rails.root.join('spec', 'fixtures', 'csv', 'import', 'miranda.jpg')
    press.update!(logo_path: Rack::Test::UploadedFile.new(replacement, 'image/jpeg'))

    expect(Press.find(press.id).logo_path.dimensions).to eq(width: 320, height: 230)
  end

  it 'invalidates cached dimensions when a file is overwritten under the same name' do
    expect(press.logo_path.dimensions).to eq(width: 305, height: 240)

    replacement = Rails.root.join('spec', 'fixtures', 'csv', 'import', 'miranda.jpg')
    File.binwrite(press.logo_path.path, File.binread(replacement))

    expect(Press.find(press.id).logo_path.dimensions).to eq(width: 320, height: 230)
  end

  it 'uses the default image dimensions after an upload is removed' do
    expect(press.logo_path.dimensions).to eq(width: 305, height: 240)
    press.remove_logo_path = true
    press.save!

    expect(Press.find(press.id).logo_path.dimensions).to eq(width: 180, height: 50)
  end

  it 'reserves the browser-oriented aspect ratio for rotated images' do
    image = MiniMagick::Image.new(press.logo_path.path)
    allow(MiniMagick::Image).to receive(:new).with(press.logo_path.path).and_return(image)
    allow(image).to receive(:[]).and_call_original
    allow(image).to receive(:[]).with('%[orientation]').and_return('RightTop')

    expect(press.logo_path.dimensions).to eq(width: 240, height: 305)
  end

  context 'with an animated GIF' do
    let(:fixture) { Rails.root.join('spec', 'fixtures', 'animated.gif') }

    it 'returns dimensions for a single frame' do
      expect(press.logo_path.dimensions).to eq(width: 365, height: 360)
    end
  end

  it 'logs missing files without preventing the existing logo markup from rendering' do
    File.unlink(press.logo_path.path)
    expect(Rails.logger).to receive(:warn).with(/Unable to read press logo dimensions/)

    expect(press.logo_path.dimensions).to eq({})
  end

  it 'logs unreadable image data without caching fabricated dimensions' do
    File.binwrite(press.logo_path.path, 'not an image')
    expect(Rails.logger).to receive(:warn).with(/Unable to read press logo dimensions/)

    expect(press.logo_path.dimensions).to eq({})
  end
end
