# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CategoriesController, type: :controller do
  describe 'GET #index' do
    it 'returns a JSON response with all categories' do
      categories = FactoryBot.create_list(:category, 3)
      
      get :index
      
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
      
      json_response = JSON.parse(response.body)
      expect(json_response.size).to eq(3)
      
      category_names = categories.map(&:name)
      json_response.each do |category|
        expect(category_names).to include(category['name'])
      end
    end
  end
end
