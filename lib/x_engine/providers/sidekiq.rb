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

# = XEngine Sidekiq Provider Source
#
# Configures, registers, and orchestrates lifecycle operations for the Sidekiq 
# integration within the +XEngine+ master container matrix.
#
# == Lifecycle Stages
#
# This provider breaks execution down into two deterministic framework gates:
#
# 1. **Prepare:** Allocates the local {XEngine::Sidekiq::Client} dependency, hooks into 
#    the database provider's post-configuration lifecycle, and registers the component keys.
# 2. **Start:** Finalizes connection matrices for both +Sidekiq.configure_server+ and 
#    +Sidekiq.configure_client+, eager loads associated command modules, and mounts them 
#    directly onto the active +Dry::CLI+ registry.
#
Dry::System.register_provider_source(:sidekiq, group: :x_engine) do
  prepare do
    # Force the core CLI component provider to finish initializing its internal maps
    target_container.start(:cli) if target_container.providers.key?(:cli)

    @sidekiq_client = XEngine::Sidekiq::Client.new
    register("sidekiq", @sidekiq_client)

    # --- DRY REFACTORED MIGRATION REGISTRATION ---
    # Instead of forcing an eager boot loop via `target_container.prepare(:database)`,
    # we standardly hook into the lifecycle events of the component itself.
    migration_path = File.expand_path("../../db/migrate", __dir__)

    target_container.after(:database) do |database_component|
      database_component.register_migration_path(migration_path)
    end
  end

  start do
    logger = target_container["logger"]

    # Configure Sidekiq global connection environments using resolved configurations
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