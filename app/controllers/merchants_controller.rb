# frozen_string_literal: true

# Reference data. Small, slow-changing and read on every app launch.
class MerchantsController < ApplicationController
  # GET /merchants
  def index
    render json: Merchant.ordered, each_serializer: MerchantSerializer
  end
end
