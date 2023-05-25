# frozen_string_literal: true

require 'rails_helper'

# Controller-level specs cover parameter handling and delegation. The wire
# contract itself is pinned end-to-end in spec/requests/transactions_spec.rb.
RSpec.describe TransactionsController, type: :controller do
  let!(:category) { create(:category, name: 'Shops') }
  let!(:transaction) { create(:transaction, category: category, reviewed: false) }

  describe 'GET #index' do
    it 'hands the whitelisted query parameters to TransactionsQuery' do
      allow(TransactionsQuery).to receive(:new).and_call_original

      get :index, params: { reviewed: 'true', per_page: '5', evil: 'DROP TABLE' }

      expect(TransactionsQuery).to have_received(:new) do |params|
        expect(params.to_unsafe_h).to eq('reviewed' => 'true', 'per_page' => '5')
      end
    end

    it 'sets the pagination headers' do
      get :index

      expect(response.headers['X-Total-Count']).to eq('1')
      expect(response.headers['X-Page']).to eq('1')
    end
  end

  describe 'PATCH #update' do
    it 'delegates to Transactions::Review' do
      allow(Transactions::Review).to receive(:call).and_call_original

      patch :update, params: { id: transaction.id, transaction: { reviewed: true } }

      expect(Transactions::Review)
        .to have_received(:call)
        .with(an_instance_of(Transaction), hash_including('reviewed' => 'true'))
      expect(response).to have_http_status(:ok)
    end

    it 'permits only reviewed, category_id and category_attributes' do
      patch :update, params: {
        id: transaction.id,
        transaction: { reviewed: true, amount: '1.00', category_attributes: { name: 'Travel', emoji: '✈️' } }
      }

      expect(transaction.reload.amount).not_to eq(BigDecimal('1.00'))
      expect(transaction.category.name).to eq('Travel')
    end

    it 'renders the service errors as a 422' do
      patch :update, params: { id: transaction.id, transaction: { category_id: 0 } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq(['Category 0 does not exist'])
    end
  end
end
