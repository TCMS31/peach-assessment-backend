# frozen_string_literal: true

# Base class for every model in the application.
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
