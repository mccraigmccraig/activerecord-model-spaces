module ActiveRecord
  module ModelSpaces

    # manages ModelSpace persistence...
    class Persistor

      attr_reader :connection
      attr_reader :table_name

      def initialize(connection, table_name)
        @connection = connection
        @table_name = table_name || "model_spaces_tables"
        create_model_spaces_table(@connection, @table_name)
      end

      # list all persisted prefixes for a given model space
      def list_keys(model_space_name)
        connection.select_rows("select model_space_key from #{table_name} where model_space_name='#{model_space_name}'").map{|r| r.first}
      end

      # returns a map of {ModelName => version} entries for a given model-space and model_space_key
      def read_model_space_model_versions(model_space_name, model_space_key)
        connection.select_all("select model_name, version from #{table_name} where model_space_name='#{model_space_name}' and model_space_key='#{model_space_key}'").reduce({}){|h,r| h[r["model_name"]] = r["version"].to_i ; h}
      end

      # update
      def update_model_space_model_versions(model_space_name, model_space_key, new_model_versions)
        ActiveRecord::Base.transaction do
          old_model_versions = read_model_space_model_versions(model_space_name, model_space_key)

          new_model_versions.map do |model_name, new_version|
            old_version = old_model_versions[model_name]

            if old_version && new_version && old_version != new_version && new_version != 0

              connection.execute("update #{table_name} set version=#{new_version} where model_space_name='#{model_space_name}' and model_space_key='#{model_space_key}' and model_name='#{model_name}'")

            elsif !old_version && new_version && new_version != 0

              connection.execute("insert into #{table_name} (model_space_name, model_space_key, model_name, version) values ('#{model_space_name}', '#{model_space_key}', '#{model_name}', #{new_version})")

            elsif old_version && ( !new_version || new_version == 0 )

              connection.execute("delete from #{table_name} where model_space_name='#{model_space_name}' and model_space_key='#{model_space_key}' and model_name='#{model_name}'")
            end
          end
          true
        end
      end

      # create the model_spaces table if it doesn't exist
      def create_model_spaces_table(connection, tn)
        if !connection.table_exists?(tn)
          connection.instance_eval do
            create_table(tn) do |t|
              t.string :model_space_name, :null=>false
              t.string :model_space_key, :null=>false
              t.string :model_name, :null=>false
              t.integer :version, :null=>false, :default=>0
            end
            add_index tn, [:model_space_name, :prefix, :model_name], :unique=>true
          end
        end
      end
    end

  end
end
