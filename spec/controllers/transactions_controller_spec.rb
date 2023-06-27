# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransactionsController, type: :controller do
  describe 'GET #index' do
    let!(:pending_review_transactions) { FactoryBot.create_list(:transaction, 3, reviewed: false) }
    let!(:reviewed_transactions) { FactoryBot.create_list(:transaction, 2, reviewed: true) }
    let!(:all_transactions) { pending_review_transactions + reviewed_transactions }
    
    context 'when no specific parameters are provided' do
      it 'returns a JSON response with all transactions' do
        get :index
        
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')
        
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(all_transactions.size)
        
        transaction_ids = all_transactions.map(&:id)
        json_response.each do |transaction|
          expect(transaction_ids).to include(transaction['id'])
        end
      end
    end
    
    context 'when "pending_review" parameter is provided' do
      it 'returns a JSON response with pending review transactions' do
        get :index, params: { pending_review: true }
        
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')
        
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(pending_review_transactions.size)
        
        transaction_ids = pending_review_transactions.map(&:id)
        json_response.each do |transaction|
          expect(transaction_ids).to include(transaction['id'])
        end
      end
    end
    
    context 'when "reviewed" parameter is provided' do
      it 'returns a JSON response with reviewed transactions' do
        get :index, params: { reviewed: true }
        
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')
        
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(reviewed_transactions.size)
        
        transaction_ids = reviewed_transactions.map(&:id)
        json_response.each do |transaction|
          expect(transaction_ids).to include(transaction['id'])
        end
      end
    end
  end
  
  describe 'GET #show' do
    let!(:transaction) { create(:transaction) }
    
    it 'returns a JSON response with the transaction' do
      get :show, params: { id: transaction.id }
      
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
      
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(transaction.id)
    end
  end

  describe 'PATCH #update' do
    let!(:transaction) { create(:transaction) }
    
    context 'with valid parameters' do
      it 'updates the transaction and returns a JSON response with the updated transaction' do
        patch :update, params: { id: transaction.id, transaction: { reviewed: true } }
        transaction.reload
        
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')
        
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(transaction.id)
        expect(transaction.reviewed).to eq(true)
      end
    end    
  end
  
  
end
