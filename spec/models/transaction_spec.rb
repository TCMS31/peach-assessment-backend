# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe "associations" do
    it { should belong_to(:merchant) }
    it { should belong_to(:category) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:amount) }
  end

  describe "scopes" do
    describe ".reviewed" do
      let!(:reviewed_transaction) { create(:transaction, reviewed: true) }
      let!(:unreviewed_transaction) { create(:transaction, reviewed: false) }

      it "returns only reviewed transactions" do
        expect(Transaction.reviewed).to eq([reviewed_transaction])
      end
    end

    describe ".pending_review" do
      let!(:reviewed_transaction) { create(:transaction, reviewed: true) }
      let!(:unreviewed_transaction) { create(:transaction, reviewed: false) }

      it "returns only transactions pending review" do
        expect(Transaction.pending_review).to eq([unreviewed_transaction])
      end
    end
  end
end
