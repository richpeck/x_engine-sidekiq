# :stopdoc:
################################################################
################################################################
##   _______      ___    ___ _________  _______   ________   ________  ___  ________  ________      
##  |\  ___ \    |\  \  /  /|\___   ___\\  ___ \ |\   ___  \|\   ____\|\  \|\   __  \|\   ___  \    
##  \ \   __/|   \ \  \/  / ||___ \  \_\ \   __/|\ \  \\ \  \ \  \___|\ \  \ \  \|\  \ \  \\ \  \   
##   \ \  \_|/__  \ \    / /     \ \  \ \ \  \_|/_\ \  \\ \  \ \_____  \ \  \ \  \\\  \ \  \\ \  \  
##    \ \  \_|\ \  /     \/       \ \  \ \ \  \_|\ \ \  \\ \  \|____|\  \ \  \ \  \\\  \ \  \\ \  \ 
##     \ \_______\/  /\   \        \ \__\ \ \_______\ \__\\ \__\____\_\  \ \__\ \_______\ \__\\ \__\
##      \|_______/__/ /\ __\        \|__|  \|_______|\|__| \|__|\_________\|__|\|_______|\|__| \|__|
##               |__|/ \|__|                                   \|_________|                         
##  --
##  RPECK 22/04/2026 - XEngine Shopify Extension
##  Class providing the means to manage how the Shopify extension interfaces with the XEngine core
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

module XEngine
  module Sidekiq
    # = Sidekiq Extension Controller
    #
    # This class manages the registration and configuration of Sidekiq workers,
    # establishing the connection to the backing store during the boot phase.
    class Extension < Core::Extension

      # Trigger the base class registration logic.
      # Identifies the extension as +:sidekiq+ within the {XEngine::Core::Registry}.
      identifier :sidekiq
      
      # Returns the absolute path to the gem's root directory.
      # @return [Pathname]
      def self.root
        Pathname.new(File.expand_path('../../..', __dir__))
      end

      # ---
      # :section: Lifecycle Hooks
      # ---

      # Phase 1: Registration
      #
      # Injects the Sidekiq configuration schema into {XEngine::Core::Configuration}.
      #
      # === Config Options:
      # [redis_url]   The URL for the Redis/Dragonfly instance (Default: ENV['XENGINE_REDIS_URL'])
      # [concurrency] Number of concurrent threads (Default: ENV['XENGINE_SIDEKIQ_CONCURRENCY'] or 5)
      # [queue]       The default queue name (Default: ENV['XENGINE_SIDEKIQ_QUEUE'] or 'default')
      # [retry_limit] Number of times to retry failed jobs (Default: ENV['XENGINE_SIDEKIQ_RETRY'] or 3)
      def self.on_register
        XEngine::Core::Configuration.setting :sidekiq do
          setting :redis_url,   default: ENV.fetch("XENGINE_REDIS_URL", "redis://localhost:6379/0")
          setting :concurrency, default: ENV.fetch("XENGINE_SIDEKIQ_CONCURRENCY", 5).to_i
          setting :queue,       default: ENV.fetch("XENGINE_SIDEKIQ_QUEUE", "default")
          setting :retry_limit, default: ENV.fetch("XENGINE_SIDEKIQ_RETRY", 3).to_i
        end
      end

      # Phase 2: Boot
      #
      # Invoked by +XEngine.boot!+. This configures the Sidekiq server/client 
      # and integrates the CLI commands.
      def self.on_boot
        return unless defined?(::Sidekiq)

        # Apply the configured Redis URL to Sidekiq
        url = XEngine.configuration.sidekiq.redis_url
        
        ::Sidekiq.configure_server { |c| c.redis = { url: url } }
        ::Sidekiq.configure_client { |c| c.redis = { url: url } }

        # Register CLI commands if the Core CLI is present
        if defined?(XEngine::Core::CLI)
          XEngine::Core::CLI.add_command "sidekiq", XEngine::Sidekiq::CLI::Commands::Sidekiq
        end
      end
    end
  end
end