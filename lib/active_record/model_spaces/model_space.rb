require 'set'
require 'active_support'
require 'active_record/model_spaces/context'
require 'active_record/model_spaces/persistor'
require 'active_record/model_spaces/table_names'
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

      def register_model(model, opts=nil)
        raise "#{model} is not an ActiveRecord model Class" if !is_active_record_model?(model)
        opts ||= {}
        ModelSpaces.check_model_registration_keys(opts.keys)
        set_model_registration(model, opts.merge(:model=>model))
        self
      end

      def deregister_model(model)
        delete_model_registration(model)
      end

      def history_versions(model)
        get_model_registration(model)[:history_versions] || 0
      end

      def set_base_table_name(model, table_name)
        get_model_registration(model)[:base_table_name] = table_name
      end

      def registered_model(model)
        get_model_registration(model)[:model]
      end

      def registered_model_name(model)
        name_from_model(get_model_registration(model)[:model])
      end

      def base_table_name(model)
        r = get_model_registration(model)
        r[:base_table_name] || TableNames.base_table_name(r[:model])
      end

      def registered_model_keys
        self.model_registrations.keys
      end

      def is_registered?(model)
        !!unchecked_get_model_registration(model)
      end

      def create_context(model_space_key)
        ctx = Context.new(self, model_space_key, ModelSpaces.create_persistor)
      end

      def kill_context(model_space_key)
        Context.drop_tables(self, model_space_key)
      end

      private

      def unchecked_get_model_registration(model)
        mc = all_model_superclasses(model).find do |klass|
          model_registrations[name_from_model(klass)]
        end
        self.model_registrations[name_from_model(mc)] if mc
      end

      def get_model_registration(model)
        r = unchecked_get_model_registration(model)
        raise "model: #{model.to_s} is not registered in ModelSpace: #{name}" if !r
        r
      end

      def set_model_registration(model, registration)
        self.model_registrations[name_from_model(model)] = registration
      end

      def delete_model_registration(model)
        self.model_registrations.delete(name_from_model(model))
      end
    end

    private

    module_function

    MODEL_REGISTRATION_KEYS = [:history_versions, :base_table_name].to_set

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
