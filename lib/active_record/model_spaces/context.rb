require 'active_record/model_spaces/table_names'

module ActiveRecord
  module ModelSpaces

    # holds the current and working tables for a ModelSpace
    class Context

      attr_reader :model_space
      attr_reader :model_space_key
      attr_reader :persistor
      attr_reader :current_model_versions
      attr_reader :working_model_versions

      def initialize(model_space, model_space_key, persistor)
        @model_space = model_space
        @model_space_key = model_space_key
        @persistor = persistor
        @current_model_versions = persistor.read_model_space_model_versions(model_space.name, model_space_key)
        @working_model_versions = {}
      end

      # implements the Model.table_name method
      def table_name(model)
        version = working_model_versions[model] || current_model_versions[model]
        table_name_from_model_version(model, version)
      end

      # base table name
      def base_table_name(model)
        TableNames.base_table_name(model)
      end

      # current table_name, seen by everyone outside of this context
      def current_table_name(model)
        table_name_from_model_version(model, current_model_versions[model])
      end

      # table_name which would be seen by this context in or after a new_version/updated_version. always returns a name
      def next_table_name(model)
        current_version = current_model_versions[model]
        next_version = TableNames.next_version(model_space.history_versions(model), current_version)
        table_name_from_model_version(model, next_version)
      end

      # table_name of working table, seen by this context in or after new_version/updated_version. null if no new_version/updated_version has been issued/completed
      def working_table_name(model)
        table_name_from_model_version(model, working_model_versions[model]) if working_model_versions[model]
      end

      def new_version(model, copy_old_version=false, &block)

        if working_model_versions[model]
          block.call # nothing to do
        else
          current_version = current_model_versions[model]
          next_version = TableNames.next_version(model_space.history_versions(model), current_version)

          if next_version != current_version
            ok = false
            begin
              tm = TableManager.new(model)
              tm.recreate_table(base_table_name(model), next_table_name(model))
              tm.copy_table(current_table_name(model), next_table_name(model)) if copy_old_version
              working_model_versions[model] = next_version
              block.call
            ensure
              working_model_versions.delete[model] if !ok
            end

          else
            block.call # nothing to do
          end
        end
      end

      def updated_version(model, &block)
        new_version(model, true, &block)
      end

      # copy all data to the base model-space tables and drop all history tables
      def hoover
        versions = read_model_space_model_versions(model_space_name, prefix)

        ActiveRecord::Base.transaction do
          new_versions = Hash.new( versions.map do |model, version|
                                     current_name = table_name(model)
                                     base_name = base_table_name(model)

                                     if current_name != base_name
                                       tm = TableManager.new(model)
                                       tm.truncate_table(base_name)
                                       tm.copy_table(current_name,base_name)
                                     end

                                     [model, 0]
                                   end)
          persistor.update_model_space_model_versions(new_versions)
        end
      end

      def commit
        persistor.update_model_space_model_versions(current_model_versions.merge(working_model_versions))
      end


      private

      def table_name_from_model_version(model, version)
        TableNames.table_name(model_space.name, model_space_key, model, model_space.history_versions(model), version)
      end
    end
  end
end
