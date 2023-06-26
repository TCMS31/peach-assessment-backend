class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show update]
  skip_before_action :verify_authenticity_token, only: [:update]

  def index
    if params[:pending_review]
      render json: Transaction.pending_review
    elsif params[:reviewed]
      render json: Transaction.reviewed
    else
      render json: Transaction.all
    end
  end

  def show
    render json: @transaction, status: :ok
  end

  def update
    if @transaction.update(transaction_params)
      render json: @transaction, status: :ok
    else
      render json: { message: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def transaction_params
    params.require(:transaction).permit(:reviewed, category_attributes: [:name, :emoji])
  end

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end
end
