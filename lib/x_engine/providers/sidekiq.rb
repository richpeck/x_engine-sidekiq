# :stopdoc:
################################################################
################################################################
##   ________  ___  ________  _______   ___  __    ___  ________      
##  |\   ____\|\  \|\   ___ \|\  ___ \ |\  \|\  \ |\  \|\   __  \     
##  \ \  \___|\ \  \ \  \_|\ \ \   __/|\ \  \/  /|\ \  \ \  \|\  \    
##   \ \_____  \ \  \ \  \ \\ \ \  \_|/_\ \   ___  \ \  \ \  \\\  \   
##    \|____|\  \ \  \ \  \_\\ \ \  \_|\ \ \  \\ \  \ \  \ \  \\\  \  
##      ____\_\  \ \__\ \_______\ \_______\ \__\\ \__\ \__\ \_____  \ 
##     |\_________\|__|\|_______|\|_______|\|__| \|__|\|__|\|___| \__\
##     \|_________|                                              \|__|
##  --
##  RPECK 29/04/2026 - Configuration Provider Source
##  Exposes core setting structures natively to the engine container
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require "sidekiq"

Dry::System.register_provider_source(:sidekiq, group: :x_engine) do
  prepare do
    # Force the core CLI component provider to finish initializing its internal maps
    target_container.start(:cli) if target_container.providers.key?(:cli)

    @sidekiq_client = XEngine::Sidekiq::Client.new
    register("sidekiq", @sidekiq_client)

    extension_migrations = File.expand_path("../../db/migrate", __dir__)
    target_container.prepare(:database)
    if target_container.key?("database")
      target_container["database"].register_migration_path(extension_migrations)
    end
  end

  start do
    logger = target_container["logger"]

    ::Sidekiq.configure_server { |c| c.redis = { url: @sidekiq_client.config.redis_url, size: @sidekiq_client.config.pool } }
    ::Sidekiq.configure_client { |c| c.redis = { url: @sidekiq_client.config.redis_url, size: @sidekiq_client.config.pool } }

    # 1. FORCE THE COMMAND NAMESPACE TO LOAD IN MEMORY NOW
    # This manually pushes through the Zeitwerk layer to make sure your class file is read
    ::XEngine::Sidekiq::LOADER.eager_load_dir(File.expand_path("../sidekiq/cli", __dir__))

    # 2. SEAMLESS INJECTION
    # Now that the class is safely loaded, register it directly to the active CLI registry
    if target_container.key?(:cli)
      target_container[:cli].register("sidekiq", XEngine::Sidekiq::CLI::Commands::Sidekiq)
    end

    if logger
      logger.info("Sidekiq integration initialized with Redis: #{@sidekiq_client.config.redis_url}")
    end
  end
end