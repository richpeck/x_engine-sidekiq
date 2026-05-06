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

# = XEngine Sidekiq
#
# The Sidekiq extension orchestrates background task execution for the XEngine 
# ecosystem. It provides the necessary plumbing to connect behavior tree nodes 
# to asynchronous workers using DragonflyDB/Redis.
#
# It utilizes +Zeitwerk+ for lazy-loading and registers itself into the 
# {XEngine::Core::Registry} to participate in the engine's global boot sequence.
module XEngine
  module Sidekiq
    # :stopdoc:
    # Initialize Zeitwerk to handle constant loading within the XEngine namespace.
    @loader ||= Zeitwerk::Loader.for_gem_extension(XEngine).tap do |l|
      l.inflector.inflect("cli" => "CLI")
      l.setup
    end
    # :startdoc:
  end
end

# Register the extension with the Core Registry only if not already present.
# This prevents Dry::Container::Error during duplicate load attempts.
unless XEngine::Core::Registry.container.key?("extensions.sidekiq")
  XEngine::Core::Registry.register_extension(:sidekiq, XEngine::Sidekiq::Extension)
end