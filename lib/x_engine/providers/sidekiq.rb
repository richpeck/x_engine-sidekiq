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
  # === Lifecycle Operations
  # 1. Synchronizes safe boot checks to verify core CLI infrastructure maps are initialized.
  # 2. Injects the extension gem's library directory paths into the application component scanner.
  # 3. Assigns the automatically managed configuration client interface directly to the container registry slot.
  #
  # @return [void]
  prepare do
    extension_lib_dir = File.expand_path("../..", __dir__)

    if target_container.providers.key?(:cli)
      target_container.start(:cli)
    end

    # Let dry-system completely replace Zeitwerk. It will handle the directory 
    # monitoring and dynamic file resolution by itself.
    target_container.config.component_dirs.add(extension_lib_dir) do |dir|
      dir.namespaces.add "x_engine", key: nil
      dir.auto_register = true
    end

    register("sidekiq") { target_container["x_engine.sidekiq.client"] }
  end

  # Activates the Sidekiq provider and wires subsystem database dependencies.
  #
  # === System Automations Executed
  # 1. *Connection Binding* - Maps server and client middleware configurations to active Redis connection strings.
  # 2. *Extension Migration Injection* - Pushes engine-specific background schema updates directly onto the orchestrator layer.
  #
  # @return [void]
  start do
    logger = target_container["logger"]
    client = target_container["sidekiq"]

    # Configure global redis/connection pooling for Sidekiq worker states 
    # out of the dry-configurable client instance settings map.
    ::Sidekiq.configure_server do |config|
      config.redis = { url: client.config.redis_url }
    end

    ::Sidekiq.configure_client do |config|
      config.redis = { url: client.config.redis_url }
    end

    # Tie cleanly into the dry-system finalization pipeline:
    # If the root application container has a configured Zeitwerk autoloader,
    # instruct it to upfront load your sidekiq CLI namespace right now.
    if target_container.respond_to?(:autoloader) && target_container.autoloader
      target_container.autoloader.eager_load_namespace(XEngine::Sidekiq::CLI)
    end

    # == Dynamic Extension Migration Injection
    if target_container.providers.key?(:database)
      migration_path = File.expand_path("../sidekiq/db/migrate", __dir__)
      target_container["database"].register_migration_path(migration_path)
    end

    # == System Telemetry Output
    logger&.info("Sidekiq background subsystem initialized against target worker pool.")
  end
end