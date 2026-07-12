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
Dry::System.register_provider_source(:sidekiq, group: :x_engine) do

  # Prepares the Sidekiq background framework dependencies within the master container.
  #
  # This lifecycle phase ensures the local database migration paths are registered
  # with the engine's database provider and defines the factory for the main
  # Sidekiq client component.
  #
  # @return [void]
  prepare do
    gem_root          = XEngine::Sidekiq::ROOT
    extension_lib_dir = File.join(gem_root, "lib")

    # 1. Register the structural migration path belonging to this extension
    if target_container.providers.key?(:database)
      migration_path = File.expand_path("x_engine/sidekiq/db/migrate", extension_lib_dir)
      target_container["database"].register_migration_path(migration_path)
    end

    # 2. Register the sidekiq client factory.
    # The client is resolved lazily via XEngine::Sidekiq::Client, which is 
    # discovered and autoloaded by the engine's Zeitwerk instance.
    register("sidekiq") do
      # Enforce early CLI setup if present to safely prepare prerequisite variables
      target_container.start(:cli) if target_container.providers.key?(:cli)
      XEngine::Sidekiq::Client.new
    end
  end

  # Activates the Sidekiq provider and wires subsystem database dependencies.
  #
  # Binds server and client middleware configurations to active Redis connection strings,
  # manages namespace eager loading, and outputs system telemetry.
  #
  # @return [void]
  start do
    client = target_container["sidekiq"]
    logger = target_container["logger"]

    # Configure global redis/connection pooling for Sidekiq worker states 
    # out of the dry-configurable client instance settings map.
    ::Sidekiq.configure_server do |config|
      config.redis = { url: client.config.redis_url }
    end

    ::Sidekiq.configure_client do |config|
      config.redis = { url: client.config.redis_url }
    end

    # If the root application container has an active autoloader, eager load the CLI namespace
    if target_container.respond_to?(:autoloader) && target_container.autoloader
      target_container.autoloader.eager_load_namespace(XEngine::Sidekiq::CLI)
    end

    logger&.info("Sidekiq background subsystem initialized against target worker pool.")
  end
end