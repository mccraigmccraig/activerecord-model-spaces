require 'active_record'
require 'active_record/model_spaces/model_space'

module ActiveRecord
  module ModelSpaces

    class Registry

      attr_reader :model_spaces
      attr_reader :model_spaces_by_models
      attr_reader :context_stack
      attr_reader :merged_context

      def initialize
        @context_stack = []
        @model_spaces = {}
        @model_spaces_by_models = {}
      end

      def register_model(model, model_space_name, opts={})
        ms = register_model_space(model_space_name).register_model(model, opts)
        register_model_space_for_model(model, ms)
      end

      def table_name(model)
        get_context_for_model(model).table_name(model)
      end

      def current_table_name(model)
        get_context_for_model(model).current_table_name(model)
      end

      def working_table_name(model)
        get_context_for_model(model).working_table_name(model)
      end

      # create a new version of the model
      def new_version(model, &block)
        get_context_for_model(model).new_version(model, &block)
      end

      # create an updated version of the model
      def updated_version(model, &block)
        get_context_for_model(model).updated_version(model, &block)
      end

      def hoover(model)
        get_context_for_model(model).hoover
      end

      # execute a block with a ModelSpace context.
      # only a single context can be active for a given ModelSpace at
      # any time, though different contexts can be active for
      # different ModelSpaces
      def with_model_space_context(model_space_name, model_space_key, &block)

        ms = get_model_space(model_space_name)
        raise "no such model space: #{model_space_name}" if !ms

        old_merged_context = nil
        ctx = ms.create_context(model_space_key)
        self.context_stack << ctx
        begin
          old_merged_context = @merged_context
          @merged_context = merge_context_stack

          r = block.call
          ctx.commit
          r
        ensure
          context_stack.pop
          @merged_context = old_merged_context
        end
      end

      private

      def register_model_space(model_space_name)
        model_spaces[model_space_name.to_sym] ||= ModelSpace.new(model_space_name.to_sym)
      end

      def get_model_space(model_space_name)
        model_spaces[model_space_name.to_sym]
      end

      def model_key(model)
        ActiveSupport::Inflector.underscore(model.to_s)
      end

      def register_model_space_for_model(model, model_space)
        raise "#{model.to_s}: already registered to model space: #{get_model_space_for_model(model).name}" if get_model_space_for_model(model)

        model_spaces_by_models[model_key(model)] = model_space
      end

      def get_model_space_for_model(model)
        model_spaces_by_models[model_key(model)]
      end

      # merge all entries in the context stack into a map
      def merge_context_stack
        context_stack.reduce({}) do |m, ctx|
          raise "ModelSpace: #{ctx.model_space.name}: already has an active context" if m[ctx.model_space.name]
          m[ctx.model_space.name] = ctx
          m
        end
      end

      def get_context_for_model(model)
        ms = get_model_space_for_model(model)
        raise "#{model.to_s} is not registered to any ModelSpace" if !ms
        raise "ModelSpace: '#{ms.name}' has no current context" if !merged_context
        ctx = self.merged_context[ms.name]
        raise "ModelSpace: '#{ms.name}' has no current context" if !ctx
        ctx
      end
    end
  end
end
