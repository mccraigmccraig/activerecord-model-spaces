require 'active_record/model_spaces/util'

module ActiveRecord
  module ModelSpaces


    # manages the creation and destruction of tables, and the bulk handling of data in those tables
    class TableManager
      include Util

      attr_reader :model
      attr_reader :connection

      def initialize(model)
        @model = model_from_name(model)
        @connection = @model.connection
      end

      # create a new table with the same schema as the base_table, but a different name
      def create_table(base_table_name, table_name)
        if table_name != base_table_name && !connection.table_exists?(table_name)
          get_table_schema_copier(connection).copy_table_schema(connection, base_table_name, table_name)
        end
      end

      # drop a table
      def drop_table(table_name)
        connection.execute("drop table #{table_name}") if connection.table_exists?(table_name)
      end

      # drop and recreate a table
      def recreate_table(base_table_name, table_name)
        if table_name != base_table_name
          drop_table(table_name)
          create_table(base_table_name, table_name)
       end
      end

      # truncate a table
      def truncate_table(table_name)
        connection.execute("truncate table #{table_name}")
      end

      # copy all data from one table to another
      def copy_table(from, to)
        connection.execute("insert into #{to} select * from #{from}") if from != to
      end

      private

      TABLE_SCHEMA_COPIERS = {}

      def get_table_schema_copier(connection)
        adapter_name = connection.adapter_name

        if !TABLE_SCHEMA_COPIERS[adapter_name]
          klassname = "ActiveRecord::ModelSpaces::#{adapter_name}TableSchemaCopier"
          klass = class_from_classname(klassname)
          if klass
            TABLE_SCHEMA_COPIERS[adapter_name] = klass
          else
            TABLE_SCHEMA_COPIERS[adapter_name] = DefaultTableSchemaCopier
          end
        end

        TABLE_SCHEMA_COPIERS[adapter_name]
      end

    end

    module MySQLTableSchemaCopier
      module_function

      def copy_table_schema(connection, from_table_name, to_table_name)
        from_table_schema = table_schema(connection, from_table_name)
        to_table_schema = change_table_name(from_table_name, to_table_name, from_table_schema)
        connection.execute(to_table_schema)
      end

      def table_schema(connection, table_name)
        connection.select_rows("SHOW CREATE TABLE `#{table_name}`").last.last
      end

      def change_table_name(from_table_name, to_table_name, schema)
        schema.gsub(/CREATE TABLE `#{from_table_name}`/, "CREATE TABLE `#{to_table_name}`")
      end
    end

    module DefaultTableSchemaCopier
      module_function

      def copy_table_schema(connection, from_table_name, to_table_name)
        from_table_schema = table_schema(connection, from_table_name)
        to_table_schema = change_table_name(from_table_name, to_table_name, from_table_schema)
        connection.instance_eval(to_table_schema)
      end

      # retrieve a schema.rb fragment pertaining to the table called table_name. uses a private Rails API
      def table_schema(connection, table_name)
        ActiveRecord::SchemaDumper.send(:new, connection).send(:table, table_name, StringIO.new).string
      end

      # change the table_name in a schema.rb fragment
      def change_table_name(base_table_name, table_name, schema)
        schema.
          gsub(/create_table \"#{base_table_name}\"/, "create_table \"#{table_name}\"").
          gsub(/add_index \"#{base_table_name}\"/, "add_index \"#{table_name}\"")
      end
    end
  end
end
