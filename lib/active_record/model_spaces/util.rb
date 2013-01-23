module ActiveRecord
  module ModelSpaces

    module Util

      module_function

      def model_name(model)
        model.to_s
      end

      def model_from_name(key)
        if key.is_a? String
          eval(key)
        else
          key
        end
      end

    end

  end
end
