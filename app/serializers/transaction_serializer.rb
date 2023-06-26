class TransactionSerializer < ActiveModel::Serializer
  attributes :id, :name, :date, :amount, :reviewed

  belongs_to :merchant
  belongs_to :category
end
