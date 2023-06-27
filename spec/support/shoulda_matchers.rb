RSpec.configure do |config|
  config.include(Shoulda::Matchers::ActiveRecord, type: :model)
end
