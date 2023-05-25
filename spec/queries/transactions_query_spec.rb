# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransactionsQuery do
  let!(:shops) { create(:category, name: 'Shops') }
  let!(:travel) { create(:category, name: 'Travel') }
  let!(:uber) { create(:merchant, name: 'Uber') }

  let!(:pending_old) do
    create(:transaction, reviewed: false, date: Date.new(2023, 5, 25), category: shops, merchant: uber)
  end
  let!(:pending_new) do
    create(:transaction, reviewed: false, date: Date.new(2023, 5, 29), category: travel)
  end
  let!(:done) do
    create(:transaction, reviewed: true, date: Date.new(2023, 5, 27), category: shops)
  end

  def run(params = {})
    described_class.new(ActionController::Parameters.new(params).permit!).results.to_a
  end

  describe 'no filters' do
    it 'returns everything, newest first' do
      expect(run).to eq([pending_new, done, pending_old])
    end
  end

  describe 'boolean casting' do
    it 'honours pending_review=true' do
      expect(run(pending_review: 'true')).to contain_exactly(pending_new, pending_old)
    end

    # The original controller branched on `if params[:pending_review]`. Every
    # query-string value is a String, so "false" was truthy and this returned
    # the pending list - the exact opposite of what was asked for.
    it 'honours pending_review=false as "not pending"' do
      expect(run(pending_review: 'false')).to eq([done])
    end

    it 'honours reviewed=false' do
      expect(run(reviewed: 'false')).to contain_exactly(pending_new, pending_old)
    end

    it 'honours reviewed=0' do
      expect(run(reviewed: '0')).to contain_exactly(pending_new, pending_old)
    end

    it 'rejects a value that is neither true nor false' do
      expect { run(reviewed: 'maybe') }
        .to raise_error(described_class::InvalidFilter, /reviewed must be true or false/)
    end

    it 'rejects contradictory filters instead of silently picking one' do
      expect { run(reviewed: 'true', pending_review: 'true') }
        .to raise_error(described_class::InvalidFilter, /contradict/)
    end

    it 'accepts filters that agree' do
      expect(run(reviewed: 'false', pending_review: 'true')).to contain_exactly(pending_new, pending_old)
    end
  end

  describe 'reference filters' do
    it 'filters by category_id' do
      expect(run(category_id: shops.id)).to contain_exactly(pending_old, done)
    end

    it 'filters by merchant_id' do
      expect(run(merchant_id: uber.id)).to eq([pending_old])
    end

    it 'rejects a non-numeric id' do
      expect { run(category_id: 'drop table') }
        .to raise_error(described_class::InvalidFilter, /category_id must be an integer/)
    end
  end

  describe 'pagination' do
    subject(:query) { described_class.new(ActionController::Parameters.new(page: '2', per_page: '2').permit!) }

    it 'returns the requested slice' do
      expect(query.results.to_a).to eq([pending_old])
    end

    it 'reports the unpaged total' do
      expect(query.total_count).to eq(3)
    end

    it 'reports the page count' do
      expect(query.total_pages).to eq(2)
    end

    it 'caps per_page so a client cannot ask for the whole table' do
      capped = described_class.new(ActionController::Parameters.new(per_page: '10000').permit!)

      expect(capped.per_page).to eq(described_class::MAX_PER_PAGE)
    end

    it 'falls back to page 1 for nonsense input' do
      expect(described_class.new(ActionController::Parameters.new(page: '-3').permit!).page).to eq(1)
    end

    it 'pages deterministically, with no row appearing twice' do
      first = described_class.new(ActionController::Parameters.new(page: '1', per_page: '2').permit!)
      second = described_class.new(ActionController::Parameters.new(page: '2', per_page: '2').permit!)

      expect((first.results.to_a + second.results.to_a).map(&:id).uniq.size).to eq(3)
    end
  end

  describe 'preloading' do
    it 'loads the serialized associations without a query per row' do
      queries = count_queries do
        described_class.new({}).results.each { |t| [t.category.name, t.merchant.name] }
      end

      # One for transactions, one for categories, one for merchants.
      expect(queries).to eq(3)
    end
  end

  describe 'extension seam' do
    it 'registers a new filter without touching the controller' do
      described_class.register(:named) { |scope, value| scope.where(name: value) }

      expect(run(named: pending_new.name)).to eq([pending_new])
    ensure
      described_class.filters.delete(:named)
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
