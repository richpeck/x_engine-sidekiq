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
# asynchronous worker framework within the +XEngine+ master container matrix.
#
# == Lifecycle Stages
#
# This provider breaks execution down into two deterministic framework gates:
#
# 1. **Prepare:** Allocates the instance-level +Dry::Configurable+ {XEngine::Sidekiq::Client}
#    dependency, satisfies immediate CLI runtime maps, and registers the client into the container room.
# 2. **Start:** Finalizes connection contexts for the background processor queues, 
#    dynamically injects the engine's data migration paths onto the platform's active 
#    database component layer, and outputs system telemetry.
#
Dry::System.register_provider_source(:sidekiq, group: :x_engine) do
  
  # Prepares the Sidekiq background framework dependencies within the master container.
  #
  # Ensures prerequisite providers are initialized before instantiating and 
  # registering the centralized configuration client instance.
  #
  # @return [void]
  prepare do
    # Force the core CLI component provider to finish initializing its internal maps
    target_container.start(:cli) if target_container.providers.key?(:cli)

    @sidekiq_client = XEngine::Sidekiq::Client.new
    register("sidekiq", @sidekiq_client)
  end

  # Activates the Sidekiq provider and wires subsystem database dependencies.
  #
  # Synchronizes server/client middleware configurations with active runtime configurations
  # and appends engine-specific migration files safely onto the database instance registry.
  #
  # @return [void]
  start do
    logger = target_container["logger"]

    # Configure global redis/connection pooling for Sidekiq worker states 
    # out of the dry-configurable client instance settings map.
    ::Sidekiq.configure_server do |config|
      config.redis = { url: @sidekiq_client.config.redis_url }
    end

    ::Sidekiq.configure_client do |config|
      config.redis = { url: @sidekiq_client.config.redis_url }
    end

    # 1. FORCE THE COMMAND NAMESPACE TO EAGER LOAD NOW
    # Tells Zeitwerk to eagerly evaluate everything nested under the local CLI sub-module module namespace.
    # As the files are evaluated, they will run their trailing direct registration container hooks.
    if defined?(XEngine::Sidekiq::CLI)
      XEngine::Sidekiq::LOADER.eager_load_namespace(XEngine::Sidekiq::CLI)
    end

    # == Dynamic Extension Migration Injection
    # Inspects the master container for an operational database component. If located,
    # the engine expands its local schema definitions and pushes them directly onto the
    # provider's target search path stack.
    if target_container.providers.key?(:database)
      migration_path = File.expand_path("../sidekiq/db/migrate", __dir__)
      database_component = target_container["database"]
      
      if database_component.respond_to?(:register_migration_path)
        database_component.register_migration_path(migration_path)
      end
    end

    # == System Telemetry Output
    if logger
      logger.info("Sidekiq background subsystem initialized against target worker pool.")
    end
  end
end