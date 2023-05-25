# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:merchant) }
    it { is_expected.to belong_to(:category) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_numericality_of(:amount) }

    it 'rejects a missing date with a validation error, not a database error' do
      transaction = build(:transaction, date: nil)

      expect(transaction.save).to be(false)
      expect(transaction.errors[:date]).to be_present
    end
  end

  describe 'amount precision' do
    it 'round-trips a decimal exactly, with no floating point drift' do
      transaction = create(:transaction, amount: '-2100.54')

      expect(transaction.reload.amount).to eq(BigDecimal('-2100.54'))
      expect(transaction.amount.to_s).to eq('-2100.54')
    end
  end

  describe 'scopes' do
    let!(:reviewed_transaction) { create(:transaction, reviewed: true, date: Date.new(2023, 5, 25)) }
    let!(:pending_transaction) { create(:transaction, reviewed: false, date: Date.new(2023, 5, 29)) }

    it '.reviewed returns only reviewed transactions' do
      expect(described_class.reviewed).to eq([reviewed_transaction])
    end

    it '.pending_review returns only transactions still awaiting review' do
      expect(described_class.pending_review).to eq([pending_transaction])
    end

    it '.newest_first orders by date descending' do
      expect(described_class.newest_first).to eq([pending_transaction, reviewed_transaction])
    end
  end
end
