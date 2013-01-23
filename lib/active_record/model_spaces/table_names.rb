require 'active_support'
require 'active_record/model_spaces/util'

module ActiveRecord
  module ModelSpaces
    module TableNames

      class << self
        include Util
      end

      module_function

      def base_table_name(model)
        name_from_model(model).
          instance_eval{|s| ActiveSupport::Inflector.underscore(s)}.
          instance_eval{|s| ActiveSupport::Inflector.pluralize(s)}
      end

      def model_space_table_name(model_space_name, model_space_key, model)
        if (!model_space_name || model_space_name.empty?) &&
            (model_space_key && !model_space_key.empty?)
          raise "model_space_key cannot be non-empty if model_space_name is empty"
        end

        [ ("#{model_space_name}__" if model_space_name && !model_space_name.empty?),
          ("#{model_space_key}__" if model_space_key && !model_space_key.empty?),
          base_table_name(model)].compact.join
      end

      def table_name(model_space_name, model_space_key, model, history_versions, v)
        [model_space_table_name(model_space_name, model_space_key, model),
          ("__#{v}" if v && v>0)].compact.join
      end

      def next_version(history_versions, v)
        version(history_versions, (v || 0)+1)
      end

      private

      module_function

      def is_versioned?(history_versions)
        history_versions && history_versions > 0
      end

      def version(history_versions, v)
        (v || 0) % ((history_versions || 0) + 1)
      end

    end
  end
end
