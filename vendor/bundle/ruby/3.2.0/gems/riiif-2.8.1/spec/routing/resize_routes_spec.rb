require 'spec_helper'

describe 'routes' do
  routes { Riiif::Engine.routes }

  describe 'for conversion' do
    it 'routes GET /abcd1234/full/full/0/default.jpg' do
      expect(
        get: '/abcd1234/full/full/0/default.jpg'
      ).to route_to(controller: 'riiif/images', id: 'abcd1234', action: 'show',
                    region: 'full', size: 'full', rotation: '0',
                    quality: 'default', format: 'jpg', model: 'riiif/image')
    end

    it 'routes requests with floating point percent size' do
      expect(
        get: '/abcd1234/full/pct:12.5/22.5/default.jpg'
      ).to route_to(controller: 'riiif/images', id: 'abcd1234', action: 'show',
                    region: 'full', size: 'pct:12.5', rotation: '22.5',
                    quality: 'default', format: 'jpg', model: 'riiif/image')
    end
    it 'routes requests with proportional sizes' do
      expect(
        get: '/abcd1234/full/!400,400/22.5/default.jpg'
      ).to route_to(controller: 'riiif/images', id: 'abcd1234', action: 'show',
                    region: 'full', size: '!400,400', rotation: '22.5',
                    quality: 'default', format: 'jpg', model: 'riiif/image')
    end
    it 'routes requests with pixel size' do
      expect(
        get: '/abcd1234/full/100,50/22.5/default.jpg'
      ).to route_to(controller: 'riiif/images', id: 'abcd1234', action: 'show',
                    region: 'full', size: '100,50', rotation: '22.5',
                    quality: 'default', format: 'jpg', model: 'riiif/image')
    end
    it 'routes requests with dashes in the id' do
      expect(
        get: '/abcd-1234-5678/full/full/0/default.jpg'
      ).to route_to(controller: 'riiif/images', id: 'abcd-1234-5678', action: 'show',
                    region: 'full', size: 'full', rotation: '0',
                    quality: 'default', format: 'jpg', model: 'riiif/image')
    end

    describe 'route helper' do
      it 'takes all the options' do
        expect(image_path('abcd1234', region: 'full', size: '100,50', rotation: '22.5', quality: 'default',
                                      format: 'jpg')).to eq '/images/abcd1234/full/100,50/22.5/default.jpg'
      end
      it 'has defaults' do
        expect(image_path('abcd1234', size: '100,50')).to eq '/images/abcd1234/full/100,50/0/default.jpg'
      end
    end
  end

  describe 'for info' do
    it 'routes GET /abcd1234/info.json' do
      expect(
        get: '/abcd1234/info.json'
      ).to route_to(controller: 'riiif/images', id: 'abcd1234',
                    action: 'info', format: 'json', model: 'riiif/image')
    end
    it 'has a route helper' do
      expect(info_path('abcd1234')).to eq '/images/abcd1234/info.json'
    end
  end
end
