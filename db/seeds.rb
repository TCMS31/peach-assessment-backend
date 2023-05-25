# frozen_string_literal: true

# `rails db:seed` entry point. The importer itself lives in lib/seeds.rb and is
# covered by spec/seeds_spec.rb.
require Rails.root.join('lib/seeds')

Seeds.run
