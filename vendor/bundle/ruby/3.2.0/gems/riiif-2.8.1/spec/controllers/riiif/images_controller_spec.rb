require 'spec_helper'
require 'open-uri'

RSpec.describe Riiif::ImagesController do
  let(:filename) { File.expand_path('spec/samples/world.jp2') }
  routes { Riiif::Engine.routes }

  describe '#error_image' do
    context 'with unauthorized' do
      around do |example|
        old_value = Riiif.unauthorized_image
        Riiif.unauthorized_image = filename
        example.run
        Riiif.unauthorized_image = old_value
      end
      subject { controller.send(:error_image, :unauthorized) }
      it 'gives the path to the image' do
        subject
      end
    end
  end

  describe '#show' do
    it 'sends images to the service' do
      image = double
      expect(Riiif::Image).to receive(:new).with('abcd1234').and_return(image)
      expect(image).to receive(:render).with({ 'region' => 'full', 'size' => 'full',
                                             'rotation' => '0', 'quality' => 'default',
                                             'format' => 'jpg' }).and_return('IMAGEDATA')
      get :show, params: { id: 'abcd1234', action: 'show', region: 'full', size: 'full',
                           rotation: '0', quality: 'default', format: 'jpg' }
      expect(response).to be_successful
      expect(response.body).to eq 'IMAGEDATA'
      expect(response.headers['Content-Type']).to eq 'image/jpeg'
      expect(response.headers['Link']).to eq '<http://iiif.io/api/image/2/level1.json>;rel="profile"'
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Cache-Control']).to eq "max-age=#{1.year.to_i}, private"
    end

    context 'with an unauthorized image' do
      let(:auth) { double('no auth service', can?: false) }

      before do
        allow(controller).to receive(:authorization_service).and_return(auth)
      end

      context 'with Riiif::unauthorized_image configured' do
        before do
          allow(controller).to receive(:error_image).with(:unauthorized).and_return(unauthorized_image)
        end

        let(:unauthorized_image) { double('unauthorized_image', render: 'test data') }

        it 'renders 401 and renders the unauthorized_image' do
          get :show, params: { id: 'abcd1234', action: 'show', region: 'full', size: 'full',
                               rotation: '0', quality: 'default', format: 'jpg' }
          expect(response.body).to eq 'test data'
          expect(response.code).to eq '401'
        end
      end

      context 'with Riiif::unauthorized_image left to nil' do
        it 'gives a helpful error' do
          expect do
            get :show, params: { id: 'abcd1234', action: 'show', region: 'full', size: 'full',
                                 rotation: '0', quality: 'default', format: 'jpg' }
          end.to raise_error(Riiif::ImageNotFoundError)
        end
      end
    end

    context 'with a invalid region' do
      it 'renders 400' do
        image = double('an image')
        allow(image).to receive(:render).and_raise IIIF::Image::InvalidAttributeError
        allow(Riiif::Image).to receive(:new).with('abcd1234').and_return(image)
        get :show, params: { id: 'abcd1234', action: 'show', region: '`szoW0', size: 'full',
                             rotation: '0', quality: 'default', format: 'jpg' }
        expect(response.code).to eq '400'
      end
    end

    context 'with a nonexistent image' do
      it "errors when a default image isn't sent" do
        expect do
          get :show, params: { id: 'bad_id', action: 'show', region: 'full', size: 'full',
                               rotation: '0', quality: 'default', format: 'jpg' }
        end.to raise_error(Riiif::ImageNotFoundError)
      end

      context 'with a default image set' do
        around do |example|
          old_value = Riiif.not_found_image
          Riiif.not_found_image = filename
          example.run
          Riiif.not_found_image = old_value
        end

        it "sends the default 'not found' image for failed http files" do
          not_found_image = double
          expect(Riiif::Image).to receive(:new) do |_id, file|
            raise Riiif::ImageNotFoundError unless file.present?
            not_found_image
          end.twice
          expect(not_found_image).to receive(:render).with({ 'region' => 'full', 'size' => 'full',
                                                           'rotation' => '0', 'quality' => 'default',
                                                           'format' => 'jpg' }).and_return('default-image-data')

          get :show, params: { id: 'bad_id', action: 'show', region: 'full', size: 'full',
                               rotation: '0', quality: 'default', format: 'jpg' }
          expect(response).to be_not_found
          expect(response.body).to eq 'default-image-data'
        end

        it "sends the default 'not found' image for failed files on the filesystem" do
          not_found_image = double
          expect(Riiif::Image).to receive(:new) do |_id, file|
            raise Riiif::ImageNotFoundError unless file.present?
            not_found_image
          end.twice
          expect(not_found_image).to receive(:render).with({ 'region' => 'full', 'size' => 'full',
                                                           'rotation' => '0', 'quality' => 'default',
                                                           'format' => 'jpg' }).and_return('default-image-data')

          get :show, params: { id: 'bad_id', action: 'show', region: 'full', size: 'full',
                               rotation: '0', quality: 'default', format: 'jpg' }
          expect(response).to be_not_found
          expect(response.body).to eq 'default-image-data'
        end
      end
    end
  end

  describe 'info_options' do
    it 'is successful' do
      process :info_options, method: 'OPTIONS', params: { id: 'abcd123', format: 'json' }
      expect(response).to be_successful
      expect(response.headers['Access-Control-Allow-Headers']).to eq 'Authorization'
    end
  end

  describe 'info' do
    context 'the happy path' do
      let(:image) { double }
      let(:json) { JSON.parse(response.body) }

      before do
        allow(Riiif::Image).to receive(:new).with('abcd1234').and_return(image)
        allow(image).to(
          receive(:info).and_return(Riiif::ImageInformation.new(width: 6000, height: 4000, format: 'JPEG', channels: 'rgb'))
        )
      end

      it 'returns info' do
        get :info, params: { id: 'abcd1234', format: 'json' }
        expect(response).to be_successful
        expect(json).to eq '@context' => 'http://iiif.io/api/image/2/context.json',
                           '@id' => Rails.version > '6.1' ? 'http://test.host/images/abcd1234' : 'http://test.host/abcd1234',
                           'width' => 6000,
                           'height' => 4000,
                           'format' => 'JPEG',
                           'channels' => 'rgb',
                           'profile' => ['http://iiif.io/api/image/2/level1.json', 'formats' => %w(webp jpg png)],
                           'protocol' => 'http://iiif.io/api/image'
        expect(response.headers['Link']).to eq '<http://iiif.io/api/image/2/level1.json>;rel="profile"'
        expect(response.headers['Content-Type']).to eq 'application/ld+json; charset=utf-8'
        expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
        expect(response.headers['Cache-Control']).to eq "max-age=#{1.year.to_i}, private"
      end
    end

    context 'when the info_service has an invalid result' do
      let(:image) { double }
      let(:json) { JSON.parse(response.body) }

      before do
        allow(Riiif::Image).to receive(:new).with('abcd1234').and_return(image)
        allow(image).to receive(:info).and_return(Riiif::ImageInformation.new(width: nil, height: nil))
      end

      it 'returns an error' do
        get :info, params: { id: 'abcd1234', format: 'json' }
        expect(response).to be_not_found
        expect(json).to eq 'error' => 'no info'
      end
    end

    context 'with an unauthorized image' do
      let(:auth) { double('no auth service', can?: false) }
      before do
        allow(controller).to receive(:authorization_service).and_return(auth)
      end
      it 'renders 401' do
        get :info, params: { id: 'abcd1234', format: 'json' }
        expect(response.body).to eq '{"error":"unauthorized"}'
        expect(response.code).to eq '401'
      end
    end
  end
end
