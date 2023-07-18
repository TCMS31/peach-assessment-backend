# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MerchantsController, type: :controller do
  describe 'GET #index' do
    it 'returns a JSON response with all merchants' do
      merchants = FactoryBot.create_list(:merchant, 3)
      
      get :index
      
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
      
      json_response = JSON.parse(response.body)
      expect(json_response.size).to eq(3)
      
      merchant_names = merchants.map(&:name)
      json_response.each do |merchant|
        expect(merchant_names).to include(merchant['name'])
      end
    end
  end
end
