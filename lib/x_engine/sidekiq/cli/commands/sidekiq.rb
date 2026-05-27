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
        class Sidekiq < ::Dry::CLI::Command
          desc "Start the Sidekiq worker process for XEngine"

          # ---
          # :section: Command Option Directives
          # ---

          # RPECK 03/05/2026 - Configuration options are declared with scalar fallbacks 
          # to prevent early configuration lookup race conditions during boot-up compilation sweeps.

          option :concurrency, 
                 type: :integer, 
                 desc: "Number of concurrent processing threads (defaults to XEngine config)"

          option :environment, 
                 type: :string,  
                 default: ENV.fetch("RAILS_ENV", "development"), 
                 desc: "The active environment target context (development, production, etc)"

          option :require_path,
                 type: :string,
                 default: "./config/boot.rb",
                 desc: "The absolute or relative path to the Ruby script required prior to execution initialization"

          # ---
          # :section: Process Lifecycle Execution
          # ---

          # Evaluates the contextual configuration environment, structures execution parameters, 
          # and performs a kernel process switch into Sidekiq.
          #
          # ==== Parameters
          # * +concurrency+ - Max processing thread allocation count (Integer). Pass +nil+ to fallback to framework configuration.
          # * +environment+ - Execution context tracking variable (String).
          # * +require_path+ - File target to rehydrate runtime application structures (String).
          # * +_options+ - Splat parameter container mapping stray user-supplied flags.
          #
          # [Returns] Does not return. Kernel +exec+ entirely replaces the execution path of the current process loop on success.
          def call(concurrency: nil, environment: "development", require_path: "./config/boot.rb", **_options)
            # Lazy load infrastructure setting blocks from the active core environment profile
            sidekiq_config = XEngine.configuration.sidekiq
            
            concurrency ||= sidekiq_config.concurrency
            
            # Map structural array values into sequential CLI execution arguments
            queues = Array(sidekiq_config.queue)
            queue_args = queues.map { |q| "-q #{q}" }

            # Compile array argument vectors for safe kernel process pipeline isolation
            cmd = [
              "bundle", "exec", "sidekiq",
              "-e", environment,
              "-c", concurrency.to_s,
              "-r", require_path
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
if defined?(XEngine::Core::CLI)
  XEngine::Core::CLI.register "sidekiq", XEngine::Sidekiq::CLI::Commands::Sidekiq
end