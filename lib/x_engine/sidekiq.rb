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

require "zeitwerk"
require "sidekiq"

module XEngine
  module Sidekiq
    # = Sidekiq Extension Controller
    #
    # Manages the registration and configuration of Sidekiq workers.
    class Extension < Core::Extension
      
      identifier :sidekiq

      def self.root
        Pathname.new(File.expand_path('..', __dir__))
      end

      # ---
      # :section: Lifecycle Hooks
      # ---

      def self.on_register
        XEngine::Core::Configuration.setting :sidekiq do
          setting :redis_url,   default: ENV.fetch("XENGINE_REDIS_URL", "redis://localhost:6379/0")
          setting :concurrency, default: ENV.fetch("XENGINE_SIDEKIQ_CONCURRENCY", 5).to_i
          setting :queue,       default: ENV.fetch("XENGINE_SIDEKIQ_QUEUE", "default")
          setting :retry_limit, default: ENV.fetch("XENGINE_SIDEKIQ_RETRY", 3).to_i
        end
      end

      def self.on_boot
        return unless defined?(::Sidekiq)

        ::Sidekiq.configure_server { |c| c.redis = { url: XEngine.configuration.sidekiq.redis_url } }
        ::Sidekiq.configure_client { |c| c.redis = { url: XEngine.configuration.sidekiq.redis_url } }

        if defined?(XEngine::Core::CLI)
          # WE USE A BLOCK/PROC HERE TO PREVENT IMMEDIATE RESOLUTION.
          # This allows Zeitwerk (at the bottom) to finish setting up
          # before we actually try to find the Command class.
          XEngine::Core::CLI.add_command "sidekiq", XEngine::Sidekiq::CLI::Commands::Sidekiq
        end
      end
    end
  end
end

# ---
# :section: Autoloader Setup (Bottom Load)
# ---

# :stopdoc:
loader = Zeitwerk::Loader.for_gem_extension(XEngine)
loader.inflector.inflect("cli" => "CLI")
loader.setup
# :startdoc: