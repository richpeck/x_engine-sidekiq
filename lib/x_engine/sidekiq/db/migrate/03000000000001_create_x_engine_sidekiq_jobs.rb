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

# frozen_string_literal: true

# = Sidekiq Jobs Database Provisioner
#
# Generates the framework metadata tracking table mapping internal asynchronous 
# worker lifetimes, job identifiers, error traces, and configuration parameters (+XEngine::Sidekiq::Job+).
#
# == Schema Layout Matrix
# [id]            System-managed unique primary key handling distributed lookups safely using a native +UUID+ format.
# [job_record_id] Foreign key reference pointing to the Core master job tracking node. Map utilizes <tt>uuid</tt> strategy.
# [jid]           The unique Sidekiq-generated background payload alphanumeric job token.
# [queue]         Target execution pool partition indicator identifier string.
# [status]        Active processing lifecycle step string enum tracking current payload state.
# [retry_count]   Running iteration metric tracking worker exception occurrences.
# [last_error]    Isolated text storage detailing the backtrace or message of the latest execution failure.
# [meta]          Open JSON hash payload map allocating dynamic execution parameter options.
# [created_at]    Standard ActiveRecord timestamp.
# [updated_at]    Standard ActiveRecord timestamp.
#
class CreateXEngineSidekiqJobs < XEngine::Core::Database::Migration

  # Executes schema generation transformations on the target database engine layer.
  #
  # @return [void]
  def up
    # Capture local layout parameters and compile target table structures safely
    localized_options = table_options.dup
    is_postgres = connection.adapter_name =~ /postg/i

    create_table table_name, **localized_options do |t|
      # 1. Core Relational Bridge Connection (Matches engine uuid standard with unique inline index)
      t.uuid :job_record_id, 
             null: false, 
             index: { unique: true, name: "idx_xe_sidekiq_jobs_record_uniq" }
      
      # 2. Sidekiq Execution Identifiers (With unique alphanumeric index)
      t.string :jid, 
               null: false, 
               index: { unique: true, name: "idx_xe_sidekiq_jobs_jid_uniq" }
             
      t.string :queue, null: false, default: "default"
      
      # 3. Lifecycle Step State (With standard lookup index)
      t.string :status, 
               null: false, 
               default: "queued", 
               index: { name: "idx_xe_sidekiq_jobs_status" }
      
      # 4. Exception Tracking Metrics
      t.integer :retry_count, null: false, default: 0
      t.text    :last_error
      
      # 5. Adaptive Open Document Parameter Store Block
      #    Enforces native jsonb definitions on pgsql to avoid strict operator constraints
      if is_postgres
        t.jsonb :meta, null: false, default: {}
      else
        t.json :meta, null: false, default: {}
      end

      t.timestamps
    end

    # 6. Hybrid Connection Adapter Guard
    #    Appends the intensive inverted lookup strategy explicitly when operating on production storage nodes
    if is_postgres
      add_index table_name, :meta, using: :gin, name: "idx_xe_sidekiq_jobs_meta_gin"
    end
  end

  private

  # Resolves the database target table directly from the Job model class.
  #
  # @return [String]
  def table_name
    @table_name ||= XEngine::Sidekiq::Job.table_name
  end

end