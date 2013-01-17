require 'active_support'
require 'active_record/model_spaces/model_registration'
require 'active_record/model_spaces/context'

module ActiveRecord
  module ModelSpaces

    class << self
      attr_accessor :connection
      attr_accessor :table_name
    end

    # a ModelSpace has a set of models registered with it,
    # from which a Context can be created
    class ModelSpace

      attr_reader :name
      attr_reader :model_registrations

      def initialize(name)
        @name = name.to_sym
        @model_registrations = {}
      end

      def register_model(model, opts={})
        reg = ModelRegistration.new(model, self, opts[:history_versions])
        self.model_registrations[model] = reg
        self
      end

      def create_context(prefix)
        ctx = Context.new(self, prefix, ModelSpaces.create_persistor(ModelSpaces.connection || ActiveRecord::Base.connection ))
      end
    end

    private

    module_function

    # get a persistor given a connection... returns an instance of
    # ActiveRecord::ModelSpaces::AdapterNamePersistor
    def create_persistor(connection)
      pcn = "#{connection.adapter_name}Persistor"
      Kernel.require ActiveSupport::Inflector.underscore("ActiveRecord::ModelSpaces::#{pcn}") if ! ModelSpaces.const_defined?(pcn)

      ModelSpaces.const_get(pcn).new(connection, self.table_name)
    end

    # get a TableManager suitable for use with a given adapter... returns an instance of
    # ActiveRecord::ModelSpaces::AdapterNameTableManager
    def create_table_manager(adapter_name)
      tmcn = "#{adapter_name}TableManager"
      Kernel.require ActiveSupport::Inflector.underscore("ActiveRecord::ModelSpaces::#{tmcn}") if ! ModelSpaces.const_defined?(tmcn)

      ModelSpaces.const_get(tmcn).new
    end

  end
end
