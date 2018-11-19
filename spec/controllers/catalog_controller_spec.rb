# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogController, type: :controller do
  context '#show_site_search?' do
    it { expect(controller.show_site_search?).to equal true }
  end
end
