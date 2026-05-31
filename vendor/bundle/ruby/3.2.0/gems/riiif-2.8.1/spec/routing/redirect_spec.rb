require 'spec_helper'

describe 'GET /abcd%2F1234', type: :request do
  it 'redirects, without unescaping' do
    get '/images/abcd%2F1234'
    expect(response).to redirect_to '/images/abcd%2F1234/info.json'
  end
end
