module ActiveRecord
  module ModelSpaces

    # models will declare which ModelSpace they are part of with :
    #  model_space :model_space, :history_versions=>2
    #
    class ModelRegistration
      attr_reader :model
      attr_reader :model_space
      attr_reader :history_versions

      def initialize(model, model_space, history_versions)
        @model = model
        @model_space = model_space
        @history_versions = history_versions || 0
      end
    end
  end
end
