require 'set'
require 'active_support'
require 'active_record/model_spaces/context'
require 'active_record/model_spaces/persistor'
require 'active_record/model_spaces/util'

module ActiveRecord
  module ModelSpaces

    class << self
      attr_accessor :connection
      attr_accessor :table_name
    end

    # a ModelSpace has a set of models registered with it,
    # from which a Context can be created
    class ModelSpace
      include Util

      attr_reader :name
      attr_reader :model_registrations

      def initialize(name)
        @name = name.to_sym
        @model_registrations = {}
      end

      def register_model(model, opts={})
        ModelSpaces.check_model_registration_keys(opts.keys)
        opts[:history_versions] ||= 0
        self.model_registrations[name_from_model(model)] = opts
        self
      end

      def history_versions(model)
        self.model_registrations[name_from_model(model)][:history_versions]
      end

      def registered_models
        self.model_registrations.keys
      end

      def create_context(model_space_key)
        ctx = Context.new(self, model_space_key, ModelSpaces.create_persistor)
      end

    end

    private

    module_function

    MODEL_REGISTRATION_KEYS = [:history_versions].to_set

    def check_model_registration_keys(keys)
      unknown_keys = (keys.map(&:to_sym).to_set - MODEL_REGISTRATION_KEYS).to_a
      raise "unknown keys: #{unknown_keys.inspect}" if !unknown_keys.empty?
    end

    # get a persistor given a connection... returns an instance of
    # ActiveRecord::ModelSpaces::AdapterNamePersistor
    def create_persistor
      Persistor.new(ModelSpaces.connection || ActiveRecord::Base.connection, ModelSpaces.table_name)
    end

  end
end
