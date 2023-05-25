# frozen_string_literal: true

# Base class for every endpoint.
#
# `ActionController::API` rather than `ActionController::Base`: this service
# never renders HTML, never sets a cookie and never uses a session, so the
# CSRF/session/flash middleware it inherited from the generator was dead weight.
# It also removes the need for the `skip_before_action :verify_authenticity_token`
# that used to sit on `TransactionsController#update` - an exemption that reads
# like a security hole in a controller that does set cookies.
class ApplicationController < ActionController::API
  include ExceptionHandler
end
