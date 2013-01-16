module ActiveRecord
  module ModelSpaces

    # holds the current and working tables for a ModelSpace
    class Context

      attr_reader :model_space
      attr_reader :prefix
      attr_reader :persistor
      attr_reader :current_model_tables
      attr_reader :working_model_tables

      def initialize(model_space, prefix, persistor)
        @model_space = model_space
        @prefix = prefix
        @persistor = persistor
        @current_model_tables = persistor.read_model_space_tables(model_space.name, prefix)
      end

      def new_version(model, &block)
      end

      def updated_version(model, &block)
      end


      def commit
        ActiveRecord::Base.transaction do

        end
      end
    end
  end
end
