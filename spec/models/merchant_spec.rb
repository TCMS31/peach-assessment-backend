# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Merchant, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:transactions).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    subject { build(:merchant) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'deleting a merchant that still has transactions' do
    let(:merchant) { create(:merchant) }

    before { create(:transaction, merchant: merchant) }

    it 'is refused rather than cascading into the ledger' do
      expect(merchant.destroy).to be(false)
      expect(Transaction.count).to eq(1)
    end
  end

  describe '.ordered' do
    it 'sorts by name' do
      create(:merchant, name: 'United')
      create(:merchant, name: 'Amazon')

      expect(described_class.ordered.pluck(:name)).to eq(%w[Amazon United])
    end

    it 'ignores case, whatever the database collation' do
      create(:merchant, name: 'AMC')
      create(:merchant, name: 'Amazon')
      create(:merchant, name: 'blue cross')

      expect(described_class.ordered.pluck(:name)).to eq(['Amazon', 'AMC', 'blue cross'])
    end
  end
end
