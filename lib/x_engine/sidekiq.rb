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
##  RPECK 03/05/2026 - XEngine Sidekiq
##  Integrates Sidekiq background processing into the XEngine stack.
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require "dry/system"

# = XEngine Framework Extension Suite
#
# Base namespace governing plugin layers and specialized component providers 
# stacked atop the core runtime platform.
#
module XEngine

  # = Sidekiq Extension Layer
  #
  # Integrates Sidekiq background job processing, queue monitoring topologies,
  # and distributed worker systems seamlessly into the core system graph.
  #
  module Sidekiq

    # Absolute path to the gem's root directory.
    # @return [String]
    ROOT = File.expand_path("../..", __dir__).freeze

    # Configures the engine container to recognize this extension's directory,
    # passes extension-specific acronym rules down to the global accumulation matrix,
    # and optimizes the autoloader layout.
    #
    # @param app [Dry::System::Container] The host framework container instance.
    # @return [void]
    #
    # === Example
    #   XEngine::Sidekiq.setup(XEngine::Application)
    #
    def self.setup(app)
      # Pushes extension-specific acronyms into the centralized application matrix.
      # These will be compiled safely via your custom inflector right before configuration.
      app.autoloader.inflector.inflect(
        "cli" => "CLI"
      )

      # Register the extension lib directory into the shared autoloader direct tracking loop.
      app.autoloader.push_dir(File.join(ROOT, "lib"))

      # Exclude internal provider definitions and component metadata files from Zeitwerk
      app.autoloader.ignore(
        File.join(ROOT, "lib/x_engine/providers"),
        File.join(ROOT, "lib/x_engine/sidekiq/version.rb"),
        File.join(ROOT, "lib/x_engine/sidekiq/db")
      )

      # Collapse nested data mapping models into flat namespaces
      app.autoloader.collapse(
        File.join(ROOT, "lib/x_engine/sidekiq/models")
      )
    end
  end
end

# --- SYSTEM PROVIDER GROUP MATRIX CONFIGURATION ---
# Inform the container system that this extension group's external providers are 
# located inside our isolated local +./providers+ folder.
Dry::System.register_provider_sources(File.join(__dir__, "providers"))

# --- AUTOMATIC APPLICATION ADAPTER BINDING ---
# Automatically mounts the background processor provider component onto the running 
# framework master container tree if it has been evaluated into active process memory.
if defined?(XEngine::Application)
  XEngine::Sidekiq.setup(XEngine::Application)
  XEngine::Application.register_provider(:sidekiq, from: :x_engine)
end