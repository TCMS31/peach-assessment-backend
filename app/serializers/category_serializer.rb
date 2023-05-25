# frozen_string_literal: true

# The category shape the mobile client reads. `color` and `emoji` drive the
# donut chart and the category tiles, so they are part of the contract, not
# incidental columns - see README > Design notes.
#
# Declaring this serializer also stops `created_at`/`updated_at` leaking into
# every embedded category inside every transaction.
class CategorySerializer < ActiveModel::Serializer
  attributes :id, :name, :emoji, :color, :budget
end
