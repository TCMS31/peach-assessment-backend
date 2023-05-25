# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transactions::Review do
  let!(:travel) { create(:category, name: 'Travel', emoji: '✈️', color: '#FFECC6') }
  let!(:shops) { create(:category, name: 'Shops', emoji: '🛍', color: '#B6E4FB') }
  let(:transaction) { create(:transaction, category: shops, reviewed: false) }

  describe 'marking reviewed' do
    it 'sets the flag and leaves the category alone' do
      result = described_class.call(transaction, { reviewed: true })

      expect(result).to be_success
      expect(transaction.reload.reviewed).to be(true)
      expect(transaction.category).to eq(shops)
    end

    it 'accepts the string "false" that arrives from a form-encoded client' do
      transaction.update!(reviewed: true)

      described_class.call(transaction, { reviewed: 'false' })

      expect(transaction.reload.reviewed).to be(false)
    end
  end

  describe 'recategorising by id' do
    it 'repoints the transaction at the existing category' do
      result = described_class.call(transaction, { category_id: travel.id })

      expect(result).to be_success
      expect(transaction.reload.category).to eq(travel)
    end

    it 'reports an unknown category instead of raising' do
      result = described_class.call(transaction, { category_id: 999_999 })

      expect(result).not_to be_success
      expect(result.errors).to include('Category 999999 does not exist')
      expect(transaction.reload.category).to eq(shops)
    end
  end

  describe 'recategorising by nested attributes (the shape the mobile client ships)' do
    # Regression test. `accepts_nested_attributes_for :category` on a belongs_to
    # with no id in the hash calls `build_category`, so the old code created a
    # fresh row on every review - duplicating reference data and losing `color`,
    # which the client uses to paint the donut chart.
    it 'resolves an existing category instead of creating a duplicate' do
      expect do
        described_class.call(transaction, { category_attributes: { name: 'Travel', emoji: '✈️' } })
      end.not_to change(Category, :count)

      expect(transaction.reload.category).to eq(travel)
      expect(transaction.category.color).to eq('#FFECC6')
    end

    it 'matches case-insensitively' do
      expect do
        described_class.call(transaction, { category_attributes: { name: 'travel' } })
      end.not_to change(Category, :count)

      expect(transaction.reload.category).to eq(travel)
    end

    it 'stays idempotent when the client sends the same review twice' do
      2.times do
        described_class.call(transaction, { reviewed: true, category_attributes: { name: 'Travel' } })
      end

      expect(Category.where(name: 'Travel').count).to eq(1)
    end

    it 'still allows a genuinely new category name, exactly once' do
      expect do
        described_class.call(transaction, { category_attributes: { name: 'Groceries', emoji: '🥕' } })
        described_class.call(transaction, { category_attributes: { name: 'Groceries', emoji: '🥕' } })
      end.to change(Category, :count).by(1)

      expect(transaction.reload.category.name).to eq('Groceries')
    end

    it 'rejects a blank category name' do
      result = described_class.call(transaction, { category_attributes: { name: '  ' } })

      expect(result).not_to be_success
      expect(result.errors).to include('Category name cannot be blank')
    end
  end

  describe 'combined review' do
    it 'applies the flag and the category in one write' do
      result = described_class.call(
        transaction, { reviewed: true, category_attributes: { name: 'Travel', emoji: '✈️' } }
      )

      expect(result).to be_success
      expect(transaction.reload).to have_attributes(reviewed: true, category: travel)
    end
  end
end
