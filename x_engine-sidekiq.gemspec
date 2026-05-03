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
##  RPECK 23/04/2026 - XEngine Sidekiq Gemspec
##  Extension used to integrate Sidekiq into the underlying XEngine system
################################################################
################################################################
# :startdoc:

# frozen_string_literal: true

require_relative "lib/x_engine/sidekiq/version"

# XEngine::Sidekiq provides asynchronous workflow capabilities.
#
# It provides:
# * +EnqueueWorkflow+ node for mid-pipeline offloading.
# * Background execution via the WorkflowWorker.
# * Lifecycle tracking via Sidekiq-specific metadata on JobRecords.
Gem::Specification.new do |s|
  s.name     = "x_engine-sidekiq"
  s.version  = XEngine::Sidekiq::VERSION
  s.license  = "MIT"
  s.authors  = ["Richard Peck"]
  s.email    = ["support@pcfixes.com"]
  s.homepage = "https://github.com/your-org/x_engine-sidekiq"
  s.summary  = "Sidekiq extension for XEngine background processing."
  
  # :stopdoc:
  # Included db and app directories to ensure migrations and workers are packaged
  all_files       = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.files         = all_files.grep(%r!^(lib|app|db)/!)
  s.require_paths = ["lib"]
  # :startdoc:

  # == Dependencies
  
  # Core Engine
  s.add_dependency "x_engine"
  
  # Async Infrastructure
  s.add_dependency "sidekiq", '~> 8.1', '>= 8.1.3'
  
end