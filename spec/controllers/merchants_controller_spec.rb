# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MerchantsController, type: :controller do
  describe 'GET #index' do
    it 'serializes every merchant through MerchantSerializer' do
      merchants = create_list(:merchant, 3)

      get :index

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body
      expect(payload.pluck('name')).to match_array(merchants.map(&:name))
      expect(payload.first.keys).to contain_exactly('id', 'name')
    end

    it 'returns an empty array rather than null when there are none' do
      get :index

      expect(response.parsed_body).to eq([])
    end
  end
end
