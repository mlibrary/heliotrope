# frozen_string_literal: true

require 'rails_helper'

describe CatalogController do
  context '#show_site_search?' do
    it { expect(controller.show_site_search?).to equal true }
  end
end
