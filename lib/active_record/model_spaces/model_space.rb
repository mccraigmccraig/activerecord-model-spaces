require 'active_support'

module ActiveRecord
  module ModelSpace

    # models will declare which TableMap they are part of with :
    #  table_map :map_name, :history_versions=>2
    #
    class ModelMetadata
      attr_reader :model
      attr_reader :history_versions
    end


    # holds ModelMetadata and spaces
    class TableMap

      attr_reader :model_metadata


      # sets the model space for the Thread and executes the block
      # using that model-space for this TableMap
      def with_model_space(model_space_name, &block)
        # creates a TableMapContext with the model_space
        # before running the block,
        # and if succesfully completed, committing the
        # TableMapContext
      end
    end

    # manages TableMap persistence
    class TableMapPersistor
      # list all persisted model spaces... not necessarily all model-spaces
      # since they can exist without persistence
      def list_model_spaces
      end

      # returns a map of {ModelName => TableName} entries for a given model-space
      def read_model_space_tables(model_space_name)
      end

      def update_model_space_tables(model_space_name, model_versions)
      end

      # copy all data to the base model-space table and drop all history tables
      def hoover_model_space(model_space_name)
      end
    end

    class TableMapContext
      attr_reader :model_space

      attr_reader :current_model_versions

      attr_reader :working_model_versions

      # returns the appropriate table_name for the given model
      def table_name(model)
      end

      # creates a new version of the model... after the block completes,
      # all references in this context will refer to the new version...
      # after the context commits, all references globally will refer to the new version
      def new_version(model, &block)
      end

      # creates an updated version of the model... after the block completes,
      # all references in this context will refer to the updated version...
      # after the context commits, all references globally will refer to the new version
      def updated_version(model, &block)
      end

      # persist all new/updated versions
      def commit
      end

    end





  end
end
