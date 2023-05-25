# frozen_string_literal: true

# Reference data the client needs to render a category picker.
class CategoriesController < ApplicationController
  # GET /categories
  def index
    render json: Category.ordered, each_serializer: CategorySerializer
  end
end
