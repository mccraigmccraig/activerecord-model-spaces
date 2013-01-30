require 'active_record/model_spaces/table_names'
require 'active_record/model_spaces/table_manager'
require 'active_record/model_spaces/util'

module ActiveRecord
  module ModelSpaces

    # holds the current and working tables for a ModelSpace
    class Context
      include Util

      attr_reader :model_space
      attr_reader :model_space_key
      attr_reader :persistor
      attr_reader :current_model_versions
      attr_reader :working_model_versions

      def initialize(model_space, model_space_key, persistor)
        @model_space = model_space
        @model_space_key = model_space_key.to_sym
        @persistor = persistor
        read_versions
      end

      def read_versions
        @current_model_versions = persistor.read_model_space_model_versions(model_space.name, model_space_key)
        @working_model_versions = {}
      end

      # implements the Model.table_name method
      def table_name(model)
        version = get_working_model_version(model) || get_current_model_version(model)
        table_name_from_model_version(model, version)
      end

      # base table name
      def base_table_name(model)
        TableNames.base_table_name(model)
      end

      # table_name for version 0
      def hoovered_table_name(model)
        table_name_from_model_version(model, 0)
      end

      # current table_name, seen by everyone outside of this context
      def current_table_name(model)
        table_name_from_model_version(model, get_current_model_version(model))
      end

      # table_name which would be seen by this context in or after a new_version/updated_version. always returns a name
      def next_table_name(model)
        current_version = get_current_model_version(model)
        next_version = TableNames.next_version(model_space.history_versions(model), current_version)
        table_name_from_model_version(model, next_version)
      end

      # table_name of working table, seen by this context in or after new_version/updated_version. null if no new_version/updated_version has been issued/completed
      def working_table_name(model)
        table_name_from_model_version(model, get_working_model_version(model)) if get_working_model_version(model)
      end

      def new_version(model, copy_old_version=false, &block)
        raise "new_version: a block must be supplied" if !block

        if get_working_model_version(model)
          block.call # nothing to do
        else
          current_version = get_current_model_version(model)
          next_version = TableNames.next_version(model_space.history_versions(model), current_version)

          tm = TableManager.new(model)
          ok = false
          begin
            btn = base_table_name(model)
            ctn = current_table_name(model)
            ntn = next_table_name(model)
            if next_version != current_version
              tm.recreate_table(btn, ntn)
              tm.copy_table(ctn, ntn) if copy_old_version
            else # no history
              tm.truncate_table(ntn) if !copy_old_version
            end
            set_working_model_version(model, next_version)
            r = block.call
            ok = true
            r
          ensure
            delete_working_model_version(model) if !ok
          end
        end
      end

      def updated_version(model, &block)
        new_version(model, true, &block)
      end

      # copy all data to the base model-space tables and drop all history tables
      def hoover
        raise "can't hoover with active working versions: #{working_model_versions.keys.inspect}" if !working_model_versions.empty?

        model_names = model_space.registered_model_keys

        new_versions = Hash[ model_names.map do |model_name|
                               base_name = base_table_name(model_name)
                               current_name = current_table_name(model_name)
                               hoovered_name = hoovered_table_name(model_name)

                               tm = TableManager.new(model_name)

                               # copy to hoovered table
                               if current_name != hoovered_name
                                 tm.recreate_table(base_name, hoovered_name)
                                 tm.copy_table(current_name, hoovered_name)
                               end

                               # drop history tables
                               (1..model_space.history_versions(model_name)).map do |v|
                                 htn = table_name_from_model_version(model_name, v)
                                 tm.drop_table(htn)
                               end

                               [model_name, 0]
                             end ]
        persistor.update_model_space_model_versions(new_versions)

        read_versions
      end

      def commit
        persistor.update_model_space_model_versions(model_space.name, model_space_key, current_model_versions.merge(working_model_versions))
      end


      private

      def table_name_from_model_version(model, version)
        TableNames.table_name(model_space.name, model_space_key, model, model_space.history_versions(model), version)
      end

      def get_current_model_version(model)
        raise "#{model}: not registered with ModelSpace: #{model_space.name}" if !model_space.is_registered?(model)
        self.current_model_versions[name_from_model(model)] || 0
      end

      def get_working_model_version(model)
        raise "#{model}: not registered with ModelSpace: #{model_space.name}" if !model_space.is_registered?(model)
        self.working_model_versions[name_from_model(model)]
      end

      def set_working_model_version(model, version)
        self.working_model_versions[name_from_model(model)] = version
      end

      def delete_working_model_version(model)
        self.working_model_versions.delete(name_from_model(model))
      end
    end
  end
end
