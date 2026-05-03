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

module XEngine
  module Sidekiq
    module CLI
      module Commands
        # = XEngine Sidekiq CLI
        #
        # Provides a wrapper around the +sidekiq+ binary to ensure the worker boots
        # with the correct environment, concurrency, and queue configuration 
        # defined in the +XEngine+ configuration registry.
        #
        # The +Sidekiq+ command class handles the transition from the 
        # XEngine Ruby environment to the Sidekiq background process.
        class Sidekiq < Dry::CLI::Command
          desc "Start the Sidekiq worker process for XEngine"

          # ---
          # :section: Options
          # ---

          # RPECK 03/05/2026 - Note: We avoid calling XEngine.config here 
          # to prevent boot-time race conditions. Defaults are handled in #call.

          option :concurrency, 
                 type: :integer, 
                 desc: "Number of threads (default: from XEngine config)"

          option :environment, 
                 type: :string,  
                 default: ENV.fetch("RAILS_ENV", "development"), 
                 desc: "Execution environment (development, production, etc)"

          option :require_path,
                 type: :string,
                 default: "./config/boot.rb",
                 desc: "The path to the Ruby file to require before starting"

          # ---
          # :section: Execution
          # ---

          # Builds and executes the Sidekiq shell command.
          #
          # This method uses +exec+ to replace the current process with the 
          # Sidekiq worker, ensuring signal handling (TERM, INT) is passed
          # directly to the background processor.
          #
          # === Parameters:
          # [concurrency] The thread count (Integer).
          # [environment] The runtime environment (String).
          # [require_path] Path to the boot file (String).
          def call(concurrency: nil, environment: "development", require_path: "./config/boot.rb", **)
            # Lazy load defaults from the configuration registry
            sidekiq_config = XEngine.configuration.sidekiq
            
            concurrency ||= sidekiq_config.concurrency
            
            # RPECK 03/05/2026 - Map the queue setting to Sidekiq flags
            queues = Array(sidekiq_config.queue)
            queue_args = queues.map { |q| "-q #{q}" }

            # Build the shell command array for safer execution
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
            
            # Use exec with array arguments to avoid shell injection
            exec(*cmd)
          end
        end
      end
    end
  end
end