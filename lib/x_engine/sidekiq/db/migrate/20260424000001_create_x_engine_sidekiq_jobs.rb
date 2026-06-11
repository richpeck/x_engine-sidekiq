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
##  RPECK 23/04/2026 - Sidekiq Job Migration
##  Defines the email log database table for when we send outbound SMTP requests
################################################################
################################################################

class CreateXEngineSidekiqJobs < XEngine::Core::Database::Migration

  # RPECK 03/05/2026 - Dynamically set resource for table naming logic
  # This will likely result in a table named 'xe_sidekiq_jobs'
  set_resource :sidekiq, :job

  # Defines the creation logic for the Sidekiq metadata table.
  def up
    # table_name and table_options are inherited from the base Migration class
    create_table table_name, **table_options do |t|
      # Link to the Core JobRecord
      t.string :job_record_id, null: false
      
      # Sidekiq-specific identifiers
      t.string :jid,           null: false
      t.string :queue,         default: 'default'
      t.string :status,        default: 'queued'
      
      # Tracking and Retries
      t.integer :retry_count,  default: 0
      t.text    :last_error
      
      # Flexible storage for Sidekiq worker options or arguments
      t.json    :meta,         default: {}

      t.timestamps

      # RPECK 03/05/2026 - Inline index definitions
      t.index :job_record_id, unique: true
      t.index :jid,           unique: true
      t.index :status
      t.index :meta,          using: :gin
    end
  end

end
# :startdoc: