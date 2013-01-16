require 'active_record'

require 'active_record/model_spaces/model_registration'
require 'active_record/model_spaces/model_space'

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

    def self.included(mod)
      mod.class_eval do

        include ClassMethods
      end
    end

    module ClassMethods

      # register a model as belonging to a model space
      def in_model_space(model_space_name, opts={})
        ms = register_model_space(model_space_name).register_model(self, opts)
        register_model(self, ms)
      end

      # create a new version of the model
      def new_version(&block)
        ms = get_model_space_for_model(self)
        model_spaces_merged_context[ms.name].new_version(self, &block)
      end

      # create an updated version of the model
      def updated_version(&block)
        ms = get_model_space_for_model(self)
        model_spaces_merged_context[ms.name].updated_version(self, &block)
      end
    end

    module_function

    # execute a block with a ModelSpace context.
    # only a single context can be active for a given ModelSpace at
    # any time, though different contexts can be active for
    # different ModelSpaces
    def with_model_space_context(model_space_name, prefix, &block)

      ms = get_model_space(model_space_name)

      old_merged_context = nil
      ctx = ms.create_context(prefix)
      model_space_context_stack << ctx
      begin
        old_merged_context = model_spaces_merged_context
        model_spaces_merged_context = merge_context_stack

        block.call
        ctx.commit
      ensure
        model_space_context_stack.pop
        model_spaces_merged_context = old_merged_context
      end
    end

    private

    module_function

    MODEL_SPACES_CONTEXT_STACK_KEY = "ActiveRecord::ModelSpaces::context_stack"
    MODEL_SPACES_MERGED_CONTEXT_KEY = "ActiveRecord::ModelSpaces::merged_context"

    def model_spaces_context_stack
      Thread.current[MODEL_SPACES_CONTEXT_STACK_KEY] = [] if !Thread.current[MODEL_SPACES_CONTEXT_STACK_KEY]
      Thread.current[MODEL_SPACES_CONTEXT_STACK_KEY]
    end

    def model_spaces_merged_context
      Thread.current[MODEL_SPACES_MERGED_CONTEXT_KEY]
    end

    def model_spaces_merged_context=(ctx)
      Thread.current[MODEL_SPACES_MERGED_CONTEXT_KEY] = ctx
    end

    MODEL_SPACES_REGISTRY = {}

    def register_model_space(model_space_name)
      MODEL_SPACES_REGISTRY[model_space_name.to_sym] ||= ModelSpace.new(model_space_name.to_sym)
    end

    def get_model_space(model_space_name)
      MODEL_SPACES_REGISTRY[model_space_name.to_sym]
    end

    MODEL_REGISTRY = {}

    def model_key(model)
      ActiveSupport::Inflector.underscore(model.to_s)
    end

    def register_model(model, model_space)
      mk = model_key(model)
      raise "#{model.to_s}: already registered to model space: #{MODEL_REGISTRY[mk].name}" if MODEL_REGISTRY[mk]

      MODEL_REGISTRY[mk] = model_space
    end

    def get_model_space_for_model(model)
      MODEL_REGISTRY[model_key(model)]
    end

    # merge all entries in the context stack into a map
    def merge_context_stack
      model_space_context_stack.reduce({}) do |m, ctx|
        raise "ModelSpace: #{ctx.model_space.name} : already has an active context" if m[ctx.model_space.name]
        m[ctx.model_space.name] = ctx
        m
      end
    end

  end
end
