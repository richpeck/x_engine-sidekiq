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
require "dry/system"

puts 'tester2'

# = XEngine Sidekiq Extension
#
# Integrates Sidekiq background job processing into the XEngine ecosystem.
# Coordinates internal autoloader path structures and configures distributed 
# component provider group matrices.
#
module XEngine
  module Sidekiq
    # Dedicated, high-performance Zeitwerk loader for the Sidekiq gem extension layer.
    # 
    # @return [Zeitwerk::Loader] The active tracking loader instance.
    #
    LOADER = Zeitwerk::Loader.for_gem_extension(XEngine).tap do |loader|
      # Enforce uppercase acronym conversion rules for terminal CLI boundaries
      loader.inflector.inflect("cli" => "CLI")
      
      # CRITICAL: Bypasses the providers folder so Zeitwerk doesn't mistake 
      # its contents for continuous Ruby constant namespaces.
      loader.ignore("#{__dir__}/providers")
      
      # Commit changes and establish the tracking system maps
      loader.setup
    end
  end
end

# --- SYSTEM PROVIDER GROUP MATRIX CONFIGURATION ---
# Inform the container system that this extension group's external providers are 
# located inside our isolated local +./providers+ folder.
#
# This implicitly maps the file located at <tt>lib/x_engine/providers/sidekiq.rb</tt> 
# containing the central +Dry::System.register_provider_source+ configuration schemas.
#
Dry::System.register_provider_sources(File.join(__dir__, "providers"))

# --- AUTOMATIC APPLICATION ADAPTER BINDING ---
# Automatically mounts the background processor provider component onto the running 
# framework master container tree if it has been evaluated into active process memory.
#
if defined?(XEngine::Application)
  XEngine::Application.register_provider(:sidekiq, from: :x_engine)
end