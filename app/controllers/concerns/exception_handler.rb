# frozen_string_literal: true

# Translates the exceptions this API can actually raise into JSON responses.
#
# Every body uses the same envelope - `{ "message": [...] }` - so a client only
# ever has to parse one error shape. `message` is always an array of strings,
# because model validation produces a list and a client that special-cased
# "sometimes a string, sometimes an array" is a client waiting to crash.
module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do |error|
      render_error(["#{error.model || 'Record'} not found"], :not_found)
    end

    # `params.require(:transaction)` with no `transaction` key. Previously a 500.
    rescue_from ActionController::ParameterMissing do |error|
      render_error(["Missing required parameter: #{error.param}"], :bad_request)
    end

    # A `create!`/`update!` that failed validation. Previously a 500.
    rescue_from ActiveRecord::RecordInvalid do |error|
      render_error(error.record.errors.full_messages, :unprocessable_entity)
    end

    # Raised by the query layer for a filter value it cannot honour.
    rescue_from TransactionsQuery::InvalidFilter do |error|
      render_error([error.message], :bad_request)
    end
  end

  private

  def render_error(messages, status)
    render json: { message: Array(messages) }, status: status
  end
end
