# frozen_string_literal: true

# `expect { ... }.to not_change(X, :count).and not_change(Y, :count)` - the
# negated form is needed because `.and` cannot be chained off `not_to`.
RSpec::Matchers.define_negated_matcher :not_change, :change
