# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PressStatisticsController, type: :controller do
  describe '#index' do
    context 'a press' do
      let(:press) { create :press }

      before do
        get :index, params: { press: press.subdomain }
      end

      it 'is successful' do
        expect(response).to be_successful
        expect(response).to render_template('press_statistics/index')
      end
    end
  end
end
