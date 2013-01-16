module ActiveRecord
  module ModelSpaces


    class TableManager
      attr_reader :adpater_name

      def initialize
      end

      # create a table with the same schema as the base_table
      def create_table(connection, base_table_name, table_name)
      end

      # drop a table
      def drop_table(connection, table_name)
      end

      # truncate a table
      def truncate_table(connection, table)
      end

      # copy all data from one table to another
      def copy_table(connection, from, to)
      end
    end
  end
end
