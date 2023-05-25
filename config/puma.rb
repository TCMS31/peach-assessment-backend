# frozen_string_literal: true

# One process, a thread pool sized by RAILS_MAX_THREADS. Keep it equal to the
# Active Record pool (config/database.yml reads the same variable) so a request
# never waits for a database connection.
max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }
threads min_threads_count, max_threads_count

# Long enough to sit at a debugger breakpoint in development.
worker_timeout 3600 if ENV.fetch('RAILS_ENV', 'development') == 'development'

port ENV.fetch('PORT', 3000)
environment ENV.fetch('RAILS_ENV', 'development')
pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

# Allow puma to be restarted by `bin/rails restart`.
plugin :tmp_restart
