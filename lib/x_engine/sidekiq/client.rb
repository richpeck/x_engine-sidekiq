# :stopdoc:
################################################################
################################################################
##	 ________  ___       ___  _______   ________   _________   
##	|\   ____\|\  \     |\  \|\  ___ \ |\   ___  \|\___   ___\ 
##	\ \  \___|\ \  \    \ \  \ \   __/|\ \  \\ \  \|___ \  \_| 
##	 \ \  \    \ \  \    \ \  \ \  \_|/_\ \  \\ \  \   \ \  \  
##	  \ \  \____\ \  \____\ \  \ \  \_|\ \ \  \\ \  \   \ \  \ 
##	   \ \_______\ \_______\ \__\ \_______\ \__\\ \__\   \ \__\
##	    \|_______|\|_______|\|__|\|_______|\|__| \|__|    \|__|
##  --
##  RPECK 03/05/2026 - Sidekiq Subsystem Orchestrator
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require "dry-configurable"

module XEngine
  module Sidekiq
    # = XEngine Sidekiq Client Orchestrator
    #
    # Encapsulates background processing configuration thresholds and runtime properties
    # mapping connections onto asynchronous Redis worker fabrics.
    #
    # == Container Registration
    # Rather than managing configuration globally via class-level constants, instances of this class 
    # are instantiated and managed directly within an IoC container (e.g. +XEngine::Application[:sidekiq]+).
    # This allows downstream parent applications to dynamically configure background processing infrastructure via 
    # blocks directly exposed by the container interface.
    #
    # === Target Block Interface Example
    #   XEngine::Application["sidekiq"].config do |config|
    #     config.redis_url = "redis://127.0.0.1:6379/4"
    #     config.pool      = 15
    #   end
    #
    class Client
      # Including Dry::Configurable at the instance level isolates configurations 
      # uniquely to individual allocated Sidekiq manager objects inside the container.
      include Dry::Configurable

      # @!attribute [rw] redis_url
      # Connection pointer addressing the target Redis caching framework cluster instance.
      # Defaults to <tt>"redis://localhost:6379/0"</tt>.
      # @return [String]
      setting :redis_url, default: ENV.fetch("XENGINE_SIDEKIQ_REDIS_URL", "redis://localhost:6379/0")

      # @!attribute [rw] pool
      # Connection concurrency processing thread capacity allocation limits.
      # Defaults to <tt>5</tt>.
      # @return [Integer]
      setting :pool, default: ENV.fetch("XENGINE_SIDEKIQ_CONCURRENCY", 5).to_i

      # @!attribute [rw] queues
      # Monitored message processing queues ordered by scanning priorities.
      # Defaults to <tt>["default"]</tt>.
      # @return [Array<String>]
      setting :queues, default: [ENV.fetch("XENGINE_SIDEKIQ_QUEUE", "default")]

      # @!attribute [rw] retry_limit
      # Number of permitted delivery attempts before job relocation into Dead Letter Queues.
      # Defaults to <tt>3</tt>.
      # @return [Integer]
      setting :retry_limit, default: ENV.fetch("XENGINE_SIDEKIQ_RETRY", 3).to_i

      # Overrides the standard +config+ method signature to intercept and yield configuration blocks.
      # This provides an intuitive object DSL interface for parent initializers to quickly configure settings.
      #
      # === Yields
      # * [Dry::Configurable::Config] The active instance configuration state proxy object.
      #
      # @return [Dry::Configurable::Config] The configuration manager instance.
      def config
        if block_given?
          yield super
        else
          super
        end
      end
    end
  end
end