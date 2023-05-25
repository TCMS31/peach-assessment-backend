# frozen_string_literal: true

# BACKTRACE=1 shows framework frames too, for debugging a problem that starts
# inside a gem.
Rails.backtrace_cleaner.remove_silencers! if ENV['BACKTRACE']
