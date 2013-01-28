require 'active_record'

require 'active_record/model_spaces/registry'

# Include this module in an ActiveRecord model to enable participation of the model
# in a ModelSpace.
#
# A ModelSpace has a name and, for each model, a number of history versions >= 0
#
# Once participating in a ModelSpace, a Context must be established before
# the model can be used. The context specifies a prefix and manages versioning
#
module ActiveRecord
  module ModelSpaces

    REGISTRY = Registry.new

    def self.included(mod)
      mod.class_eval do
        include ClassMethods
      end
    end

    module_function

    def with_model_space_context(model_space_name, model_space_key, &block)
      REGISTRY.with_model_space_context(model_space_name, model_space_key, &block)
    end

    module ClassMethods

      # register a model as belonging to a model space
      def in_model_space(model_space_name, opts={})
        REGISTRY.register_model(self, model_space_name, opts)
      end

      def table_name
        REGISTRY.table_name(self)
      end

      def current_table_name
        REGISTRY.current_table_name(self)
      end

      def working_table_name
        REGISTRY.working_table_name(self)
      end

      # create a new version of the model
      def new_version(&block)
        REGISTRY.new_version(self, &block)
      end

      # create an updated version of the model
      def updated_version(&block)
        REGISTRY.updated_version(self, &block)
      end

      def hoover
        REGISTRY.hoover(self)
      end
    end

  end
end
