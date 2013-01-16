require 'active_support'

module ActiveRecord
  module ModelSpaces
    module TableNames

      module_function

      def base_table_name(model)
        model.to_s.
          instance_eval{|s| ActiveSupport::Inflector.underscore(s)}.
          instance_eval{|s| ActiveSupport::Inflector.pluralize(s)}
      end

      def model_space_table_name(model, model_space_prefix)
        [("#{model_space_prefix}__" if model_space_prefix && !model_space_prefix.empty?),
          base_table_name(model)].join
      end

      def table_name(model, model_space_prefix, history_versions, v)
        [model_space_table_name(model, model_space_prefix),
          ("__#{version(history_versions, v)}" if
            is_versioned?(history_versions) &&
            v &&
            version(history_versions, v) > 0)].join
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
