# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CategoriesController, type: :controller do
  describe 'GET #index' do
    it 'serializes every category through CategorySerializer' do
      create_list(:category, 3)

      get :index

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body
      expect(payload.size).to eq(3)
      expect(payload.first.keys).to contain_exactly('id', 'name', 'emoji', 'color', 'budget')
    end

    it 'returns an empty array rather than null when there are none' do
      get :index

      expect(response.parsed_body).to eq([])
    end
  end
end
