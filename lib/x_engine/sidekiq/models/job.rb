# :stopdoc:
################################################################
################################################################
##      ___  ________  ________     
##     |\  \|\   __  \|\   __  \    
##     \ \  \ \  \|\  \ \  \|\ /_   
##   __ \ \  \ \  \\\  \ \   __  \  
##  |\  \\_\  \ \  \\\  \ \  \|\  \ 
##  \ \________\ \_______\ \_______\
##   \|________|\|_______|\|_______|
##  --
##  RPECK 03/05/2026 - Sidekiq Job
##  Extension model to track Sidekiq JID and metadata for JobRecords.
################################################################
################################################################
# :startdoc:

# = XEngine Sidekiq Job
#
# This model acts as a "Shadow Record" for +XEngine::Core::JobRecord+.
# It stores infrastructure-level metadata (JID, Queue, Retries) 
# separate from the core business logic and payload.
module XEngine
  module Sidekiq
    class Job < XEngine::Core::Model

      # == Associations
      
      # Link back to the primary execution record.
      # RPECK 03/05/2026 - Support for UUID foreign keys is inherited from ActiveRecord.
      belongs_to :job_record, 
                 class_name: "XEngine::Core::JobRecord", 
                 foreign_key: :job_record_id

      # == Validations
      
      validates :job_record_id, presence: true, uniqueness: true
      validates :jid,           presence: true, uniqueness: true
      validates :status,        presence: true

      # == Logic
      
      # Determines if the background process is currently in a lifecycle state.
      #
      # Returns [Boolean]
      def active?
        %w[queued running retrying].include?(status)
      end

      # Logs a standardized failure message and backtrace to the meta column.
      # 
      # @param error [StandardError] The caught exception.
      def log_failure!(error)
        update(
          status: 'failed',
          last_error: "#{error.class}: #{error.message}",
          meta: meta.merge({
            backtrace: error.backtrace&.first(5),
            failed_at: Time.current
          })
        )
      end

    end
  end
end