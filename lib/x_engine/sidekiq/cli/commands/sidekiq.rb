# :stopdoc:
################################################################
################################################################
##  ________  ___  ________  _______   ___  __    ___  ________      
## |\   ____\|\  \|\   ___ \|\  ___ \ |\  \|\  \ |\  \|\   __  \     
## \ \  \___|\ \  \ \  \_|\ \ \   __/|\ \  \/  /|\ \  \ \  \|\  \    
##  \ \_____  \ \  \ \  \ \\ \ \  \_|/_\ \   ___  \ \  \ \  \\\  \   
##   \|____|\  \ \  \ \  \_\\ \ \  \_|\ \ \  \\ \  \ \  \ \  \\\  \  
##     ____\_\  \ \__\ \_______\ \_______\ \__\\ \__\ \__\ \_____  \ 
##    |\_________\|__|\|_______|\|_______|\|__| \|__|\|__|\|___| \__\
##    \|_________|                                              \|__|
##
##  --
##  RPECK 03/05/2026 - Sidekiq CLI Command
##  Unified entry point for booting Sidekiq within the XEngine stack.
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require "dry/cli"

module XEngine
  module Sidekiq
    module CLI
      module Commands
        # = XEngine Sidekiq CLI Process Launcher
        #
        # A process-level management ingress command that acts as an orchestrated wrapper around 
        # the native +sidekiq+ subsystem binary. This wrapper ensures background worker loops 
        # initialize within the correct context mapping, execution thread concurrency, 
        # and queue configurations prioritized by the host application's central configuration profile.
        #
        # ==== Lifecycle & Process Handover
        #
        # To preserve operational performance and integrity, the implementation relies on a native 
        # Kernel +exec+ handover strategy. This terminates the parent XEngine launcher process and 
        # replaces it directly within the kernel process space with Sidekiq. 
        #
        # This architecture ensures all standard operating system process signals (e.g., +SIGTERM+, 
        # +SIGINT+, +SIGTSTP+) travel directly to Sidekiq's process manager for graceful termination management.
        #
        class Sidekiq < ::Dry::CLI::Command
          desc "Start the Sidekiq worker process for XEngine"

          # ---
          # :section: Command Option Directives
          # ---

          option :concurrency, 
                 type: :integer, 
                 desc: "Number of concurrent processing threads (defaults to XEngine provider configuration)"

          option :environment, 
                 type: :string,  
                 default: ENV.fetch("XENGINE_ENV", "development"), 
                 desc: "The active environment target context (development, production, etc)"

          option :require_path,
                 type: :string,
                 default: "./lib/x_engine.rb",
                 desc: "The absolute or relative path to the Ruby script required prior to execution initialization"

          # ---
          # :section: Process Lifecycle Execution
          # ---

          # Evaluates the contextual configuration environment, structures execution parameters, 
          # and performs a kernel process switch into Sidekiq.
          #
          # ==== Parameters
          # * +concurrency+  - Max processing thread allocation count (Integer).
          # * +environment+  - Execution context tracking variable (String).
          # * +require_path+ - File target to rehydrate runtime application structures (String).
          # * +_options+     - Splat parameter container mapping stray user-supplied flags.
          #
          # [Returns] Does not return. Kernel +exec+ entirely replaces the execution path of the current process loop on success.
          def call(concurrency: nil, environment: "development", require_path: "./lib/x_engine.rb", **_options)
            # DYNAMIC RESOLUTION:
            # Query the container directly for the registered "sidekiq" orchestrator client component.
            # This triggers all native late-binding host initializers automatically.
            sidekiq_client = XEngine::Application.key?("sidekiq") ? XEngine::Application["sidekiq"] : nil
            
            # Extract values out of the dry-configurable client block schema if available
            if sidekiq_client&.respond_to?(:config)
              concurrency ||= sidekiq_client.config.pool
              queues        = Array(sidekiq_client.config.queues)
            else
              concurrency ||= 5
              queues        = ["default"]
            end
            
            # Map structural array values into sequential CLI argument pairs safely
            queue_args = queues.flat_map { |q| ["-q", q.to_s] }

            # Compile absolute array argument vectors for safe kernel process pipeline isolation
            cmd = [
              "bundle", "exec", "sidekiq",
              "-e", environment.to_s,
              "-c", concurrency.to_s,
              "-r", require_path.to_s
            ] + queue_args

            puts "=> XEngine Sidekiq starting..."
            puts "=> Queues:      #{queues.join(', ')}"
            puts "=> Concurrency: #{concurrency}"
            puts "=> Environment: #{environment}"
            
            # Invoke low-level system execution substitution to bypass shell string injection vulnerabilities
            exec(*cmd)
          end
        end
      end
    end
  end
end

# --- THE CLI CORE REGISTRATION ---
# The command explicitly mounts itself straight onto the master routing table
if defined?(XEngine::Application) && XEngine::Application.key?(:cli)
  XEngine::Application[:cli].register("sidekiq", XEngine::Sidekiq::CLI::Commands::Sidekiq)
end