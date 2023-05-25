# frozen_string_literal: true

# Read the ledger and record a review. Filtering lives in TransactionsQuery and
# the write lives in Transactions::Review, so this class only translates HTTP.
class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show update]

  # GET /transactions
  #
  # The body stays a bare JSON array. The mobile client feeds the response
  # straight into `normalizeTransactions`, which returns `[]` for anything that
  # is not an array, so wrapping the collection in a `{ data: ... }` envelope
  # would blank the screen. Pagination is reported in headers instead.
  def index
    query = TransactionsQuery.new(query_params)
    apply_pagination_headers(query)
    render json: query.results, each_serializer: TransactionSerializer
  end

  # GET /transactions/:id
  def show
    render json: @transaction, status: :ok
  end

  # PATCH /transactions/:id
  def update
    result = Transactions::Review.call(@transaction, review_params)

    if result.success?
      render json: result.transaction, status: :ok
    else
      render json: { message: result.errors }, status: :unprocessable_entity
    end
  end

  private

  def query_params
    params.permit(:reviewed, :pending_review, :category_id, :merchant_id, :page, :per_page)
  end

  def review_params
    params
      .require(:transaction)
      .permit(:reviewed, :category_id, category_attributes: %i[name emoji])
  end

  def set_transaction
    @transaction = Transaction.includes(:category, :merchant).find(params[:id])
  end

  def apply_pagination_headers(query)
    response.set_header('X-Total-Count', query.total_count.to_s)
    response.set_header('X-Page', query.page.to_s)
    response.set_header('X-Per-Page', query.per_page.to_s)
    response.set_header('X-Total-Pages', query.total_pages.to_s)
  end
end
