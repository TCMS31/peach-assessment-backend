# frozen_string_literal: true

require 'rails_helper'

# End-to-end specs for the contract the React Native client in
# peach-assessment-frontend consumes. Anything asserted here is a breaking
# change for that app, so these are deliberately literal about the wire shape.
RSpec.describe 'Transactions API', type: :request do
  let!(:travel) { create(:category, name: 'Travel', emoji: '✈️', color: '#FFECC6', budget: nil) }
  let!(:shops) { create(:category, name: 'Shops', emoji: '🛍', color: '#B6E4FB', budget: nil) }
  let!(:united) { create(:merchant, name: 'United') }

  let!(:pending_flight) do
    create(:transaction, name: 'SFO to JFK', amount: '129.97', date: Date.new(2023, 5, 29),
                         reviewed: false, category: shops, merchant: united)
  end
  let!(:reviewed_coffee) do
    create(:transaction, name: 'Chipotle', amount: '12.88', date: Date.new(2023, 5, 28),
                         reviewed: true, category: shops)
  end

  def json
    response.parsed_body
  end

  describe 'GET /transactions' do
    it 'returns a bare JSON array' do
      get '/transactions'

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
      # Not an envelope: the client feeds this straight into
      # `normalizeTransactions`, which returns [] for anything else.
      expect(json).to be_an(Array)
      expect(json.size).to eq(2)
    end

    it 'embeds the exact transaction shape the client reads' do
      get '/transactions'

      payload = json.find { |t| t['id'] == pending_flight.id }

      expect(payload).to eq(
        'id' => pending_flight.id,
        'name' => 'SFO to JFK',
        'date' => '2023-05-29',
        'amount' => '129.97',
        'reviewed' => false,
        'merchant' => { 'id' => united.id, 'name' => 'United' },
        'category' => {
          'id' => shops.id, 'name' => 'Shops', 'emoji' => '🛍',
          'color' => '#B6E4FB', 'budget' => nil
        }
      )
    end

    it 'orders newest first' do
      get '/transactions'

      expect(json.pluck('date')).to eq(%w[2023-05-29 2023-05-28])
    end

    it 'filters with pending_review=true' do
      get '/transactions', params: { pending_review: true }

      expect(json.pluck('id')).to eq([pending_flight.id])
    end

    it 'filters with reviewed=true' do
      get '/transactions', params: { reviewed: true }

      expect(json.pluck('id')).to eq([reviewed_coffee.id])
    end

    it 'treats pending_review=false as "already reviewed"' do
      get '/transactions', params: { pending_review: false }

      expect(json.pluck('id')).to eq([reviewed_coffee.id])
    end

    it 'rejects an uncastable filter with 400 and a message array' do
      get '/transactions', params: { reviewed: 'yesplease' }

      expect(response).to have_http_status(:bad_request)
      expect(json['message']).to eq(['reviewed must be true or false'])
    end

    it 'rejects a page number past what OFFSET can hold with 400, not a database error' do
      get '/transactions', params: { page: '99999999999999999999' }

      expect(response).to have_http_status(:bad_request)
      expect(json['message']).to eq(['page is out of range'])
    end

    it 'returns an empty array for a page past the last one' do
      get '/transactions', params: { page: 50 }

      expect(response).to have_http_status(:ok)
      expect(json).to eq([])
      expect(response.headers['X-Total-Count']).to eq('2')
    end

    it 'reports pagination in headers, leaving the body a plain array' do
      get '/transactions', params: { per_page: 1 }

      expect(json.size).to eq(1)
      expect(response.headers['X-Total-Count']).to eq('2')
      expect(response.headers['X-Per-Page']).to eq('1')
      expect(response.headers['X-Total-Pages']).to eq('2')
    end

    it 'does not issue a query per row' do
      create_list(:transaction, 8)

      queries = count_queries { get '/transactions' }

      # transactions + categories + merchants + the COUNT for the headers.
      expect(queries).to eq(4)
    end
  end

  describe 'GET /transactions/:id' do
    it 'returns the transaction' do
      get "/transactions/#{pending_flight.id}"

      expect(response).to have_http_status(:ok)
      expect(json['id']).to eq(pending_flight.id)
      expect(json['category']['color']).to eq('#B6E4FB')
    end

    it 'returns 404 with the shared error envelope for an unknown id' do
      get '/transactions/999999'

      expect(response).to have_http_status(:not_found)
      expect(json).to eq('message' => ['Transaction not found'])
    end
  end

  describe 'PATCH /transactions/:id' do
    it 'marks a transaction reviewed and echoes it back' do
      patch "/transactions/#{pending_flight.id}", params: { transaction: { reviewed: true } }

      expect(response).to have_http_status(:ok)
      expect(json['reviewed']).to be(true)
      expect(pending_flight.reload.reviewed).to be(true)
    end

    it 'accepts a JSON body, which is what the client sends' do
      patch "/transactions/#{pending_flight.id}",
            params: { transaction: { reviewed: true } }.to_json,
            headers: { 'CONTENT_TYPE' => 'application/json' }

      expect(response).to have_http_status(:ok)
      expect(json['reviewed']).to be(true)
    end

    it 'recategorises by id' do
      patch "/transactions/#{pending_flight.id}",
            params: { transaction: { reviewed: true, category_id: travel.id } }

      expect(json['category']['id']).to eq(travel.id)
      expect(json['category']['color']).to eq('#FFECC6')
    end

    # The mobile client currently sends category_attributes. This used to mint a
    # fresh, colourless Category on every call.
    it 'recategorises by nested attributes without duplicating the category' do
      expect do
        patch "/transactions/#{pending_flight.id}",
              params: { transaction: { reviewed: true, category_attributes: { name: 'Travel', emoji: '✈️' } } }
      end.not_to change(Category, :count)

      expect(json['category']).to eq(
        'id' => travel.id, 'name' => 'Travel', 'emoji' => '✈️',
        'color' => '#FFECC6', 'budget' => nil
      )
    end

    it 'returns 422 with a message array for an unknown category' do
      patch "/transactions/#{pending_flight.id}", params: { transaction: { category_id: 999_999 } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['message']).to eq(['Category 999999 does not exist'])
    end

    it 'returns 422 for a reviewed flag it cannot read, leaving the row unchanged' do
      patch "/transactions/#{pending_flight.id}", params: { transaction: { reviewed: 'maybe' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['message']).to eq(['reviewed must be true or false'])
      expect(pending_flight.reload.reviewed).to be(false)
    end

    it 'returns 400 when the transaction key is missing, rather than a 500' do
      patch "/transactions/#{pending_flight.id}", params: { reviewed: true }

      expect(response).to have_http_status(:bad_request)
      expect(json['message']).to eq(['Missing required parameter: transaction'])
    end

    it 'ignores attributes that are not part of the review contract' do
      patch "/transactions/#{pending_flight.id}",
            params: { transaction: { reviewed: true, amount: '0.01', name: 'hacked' } }

      expect(pending_flight.reload).to have_attributes(name: 'SFO to JFK', amount: BigDecimal('129.97'))
    end

    it 'returns 404 for an unknown transaction' do
      patch '/transactions/999999', params: { transaction: { reviewed: true } }

      expect(response).to have_http_status(:not_found)
    end
  end

  # There is no User model and no authentication anywhere in this service, so
  # there is no ownership to violate - but that also means any caller can read
  # and modify any record. This pins the current behaviour so that the day
  # authentication is added, the gap is visible rather than assumed.
  describe 'access control (documented, not enforced)' do
    it 'serves and mutates every record to an unauthenticated caller' do
      get '/transactions'
      expect(response).to have_http_status(:ok)

      patch "/transactions/#{reviewed_coffee.id}", params: { transaction: { reviewed: false } }
      expect(response).to have_http_status(:ok)
      expect(reviewed_coffee.reload.reviewed).to be(false)
    end
  end

  def count_queries(&block)
    count = 0
    counter = lambda { |_name, _start, _finish, _id, payload|
      count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION CACHE])
    }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &block)
    count
  end
end
