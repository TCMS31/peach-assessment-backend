# frozen_string_literal: true

# Who the money went to or came from. Two fields is the whole contract.
class MerchantSerializer < ActiveModel::Serializer
  attributes :id, :name
end
