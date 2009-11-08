# Author: Stephen Sykes

module SlimScrooge
  # Contains the complete list of callsites
  #
  class Callsites
    CallsitesMutex = Mutex.new
    @@callsites = {}

    class << self
      # Whether we have encountered a callsite before
      #
      def has_key?(callsite_key)
        @@callsites.has_key?(callsite_key)
      end

      # Return the callsite for this key
      #
      def [](callsite_key)
        @@callsites[callsite_key]
      end

      # Generate a key string - uses the portion of the query before the WHERE 
      # together with the callsite_hash generated by callsite_hash.c
      #
      def callsite_key(callsite_hash, sql)
        callsite_hash + sql.gsub(/\sWHERE.*/i, "").hash
      end

      # Create a new callsite
      # 
      def create(sql, callsite_key, name)
        begin
          model_class = name.split.first.constantize
        rescue NameError, NoMethodError
          add_callsite(callsite_key, nil)
        else
          add_callsite(callsite_key, Callsite.make_callsite(model_class, sql))
        end
      end

      # Add a new callsite, wrap in a mutex for safety
      #
      def add_callsite(callsite_key, callsite)
        CallsitesMutex.synchronize do
          @@callsites[callsite_key] = callsite
        end
      end

      # Record that a column was accessed, wrap in a mutex for safety
      #
      def add_seen_column(callsite, seen_column)
        CallsitesMutex.synchronize do
          callsite.seen_columns << seen_column
        end
      end
    end
  end
end
