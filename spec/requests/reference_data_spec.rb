# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reference data API', type: :request do
  def json
    response.parsed_body
  end

  describe 'GET /categories' do
    before do
      create(:category, name: 'Travel', emoji: '✈️', color: '#FFECC6', budget: nil)
      create(:category, name: 'Food and Drink', emoji: '🍕', color: '#FFC9C9', budget: '250.0')
    end

    it 'returns categories ordered by name, with the fields the client renders' do
      get '/categories'

      expect(response).to have_http_status(:ok)
      expect(json).to eq(
        [
          { 'id' => Category.find_by(name: 'Food and Drink').id, 'name' => 'Food and Drink',
            'emoji' => '🍕', 'color' => '#FFC9C9', 'budget' => '250.0' },
          { 'id' => Category.find_by(name: 'Travel').id, 'name' => 'Travel',
            'emoji' => '✈️', 'color' => '#FFECC6', 'budget' => nil }
        ]
      )
    end

    it 'does not leak timestamps' do
      get '/categories'

      expect(json.first.keys).not_to include('created_at', 'updated_at')
    end
  end

  describe 'GET /merchants' do
    before do
      create(:merchant, name: 'United')
      create(:merchant, name: 'Amazon')
    end

    it 'returns id and name only, ordered by name' do
      get '/merchants'

      expect(response).to have_http_status(:ok)
      expect(json.pluck('name')).to eq(%w[Amazon United])
      expect(json.first.keys).to contain_exactly('id', 'name')
    end
  end

  describe 'GET /health' do
    it 'reports ok when the database is reachable' do
      get '/health'

      expect(response).to have_http_status(:ok)
      expect(json).to eq('status' => 'ok', 'database' => 'ok')
    end

    it 'reports 503 when the database is not reachable' do
      allow(ActiveRecord::Base).to receive(:connection).and_raise(PG::ConnectionBad, 'down')

      get '/health'

      expect(response).to have_http_status(:service_unavailable)
      expect(json).to eq('status' => 'error', 'database' => 'unavailable')
    end
  end
end
