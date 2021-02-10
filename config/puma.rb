max_threads_count = ENV.fetch("APP_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("APP_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count


port ENV.fetch("PORT") { 9292 }

pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

workers ENV.fetch("APP_WORKERS") { 3 }

preload_app!
