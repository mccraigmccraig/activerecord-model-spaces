module ActiveRecord
  module ModelSpaces

    # manages ModelSpace persistence... subclasses
    # should be provided for specific databases, named by
    # AdapterNamePersistor e.g. MySQLPersistor, PostgreSQLPersistor
    class Persistor

      attr_reader :connection
      attr_reader :table_name

      def initialize(connection, table_name)
        @connection = connection
        @table_name = table_name || "model_spaces_tables"
      end

      # list all persisted prefixes for a given model space
      def list_prefixes(model_space_name)
        raise "Implement me"
      end

      # returns a map of {ModelName => TableName} entries for a given model-space
      def read_model_space_tables(model_space_name, prefix)
        raise "Implement me"
      end

      def update_model_space_tables(model_space_name, prefix, model_tables)
        raise "Implement me"
      end

      # copy all data to the base model-space tables and drop all history tables
      def hoover_model_space(model_space_name, prefix)
        raise "Implement me"
      end

      # create the model_spaces table if it doesn't exist
      def create_model_spaces_table
      end
    end

  end
end
