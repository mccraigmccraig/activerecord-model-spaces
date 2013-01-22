module ActiveRecord
  module ModelSpaces


    # manages the creation and destruction of tables, and the bulk handling of data in those tables
    class TableManager

      attr_reader :model
      attr_reader :connection

      def initialize(model)
        @model = model
        @connection = model.connection
      end

      # create a new table with the same schema as the base_table, but a different name
      def create_table(base_table_name, table_name)
        if table_name != base_table_name
          base_table_schema = table_schema(base_table_name)
          table_schema = change_table_name(base_table_schema)
          connection.instance_eval(table_schema)
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
      def truncate_table(table)
        connection.execute("truncate table #{table_name}")
      end

      # copy all data from one table to another
      def copy_table(from, to)
        connection.execute("insert into #{to} select * from #{from}") if from != to
      end

      private

      # retrieve a schema.rb fragment pertaining to the table called table_name. uses a private Rails API
      def table_schema(table_name)
        ActiveRecord::SchemaDumper.send(:new, connection).send(:table, base_table_name, StringIO.new).string
      end

      # change the table_name in a schema.rb fragment
      def change_table_name(schema)
        schema.
          gsub(/create_table \"#{base_table_name}\"/, "create table \"#{table_name}\"").
          gsub(/add_index \"#{base_table_name}\"/, "add index \"#{table_name}\"")
      end
    end
  end
end
