# frozen_string_literal: true

require 'testing_helper'

RSpec.describe 'Testing Press Cleaner' do
  before { Testing::Target.testing_press_cleaner }

  it 'Press Cleaner is working' do
    expect(Testing::Target.testing_press_monographs).to be_empty
  end
end
