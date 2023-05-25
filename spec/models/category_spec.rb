# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:transactions).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    subject { build(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'deleting a category that still has transactions' do
    let(:category) { create(:category) }

    before { create(:transaction, category: category) }

    it 'is refused rather than cascading into the ledger' do
      expect(category.destroy).to be(false)
      expect(Transaction.count).to eq(1)
      expect(described_class.exists?(category.id)).to be(true)
    end
  end

  describe '.ordered' do
    it 'sorts by name so the client picker is stable between requests' do
      create(:category, name: 'Travel')
      create(:category, name: 'Food and Drink')
      create(:category, name: 'Shops')

      expect(described_class.ordered.pluck(:name)).to eq(['Food and Drink', 'Shops', 'Travel'])
    end
  end
end
