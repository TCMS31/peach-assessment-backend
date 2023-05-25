# frozen_string_literal: true

# Wraps the model attributes of a bare JSON body - `{"reviewed": true}` - into
# `params[:transaction]` for TransactionsController. Nested keys such as
# `category_attributes` are not wrapped, so the client sends the
# `{"transaction": {...}}` envelope for a recategorisation.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: [:json]
end
