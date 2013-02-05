module ActiveRecord
  module ModelSpaces

    module Util

      module_function

      def name_from_model(model)
        model.to_s
      end

      def model_from_name(key)
        if key.is_a? String
          Kernel.eval(key)
        else
          key
        end
      end

      def require_for_classname(classname)
        begin
          Kernel.require ActiveSupport::Inflector.underscore(classname)
          Kernel.eval(classname)
        rescue
          false
        end
      end

      def class_for_classname(classname)
        begin
          model_from_name(classname)
        rescue
          false
        end
      end

      def class_from_classname(classname)
        class_for_classname(classname) || require_for_classname(classname)
      end

      # returns all model superclasses upto but not including ActiveRecord::Base
      def all_model_superclasses(klass)
        superclasses = klass.ancestors.grep(Class).sort.take_while{|k| k < ActiveRecord::Base}
      end

    end

  end
end
