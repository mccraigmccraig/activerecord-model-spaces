require 'active_record'
require 'active_record/model_spaces/model_space'

module ActiveRecord
  module ModelSpaces

    class Registry
      include Util

      attr_reader :model_spaces
      attr_reader :model_spaces_by_models
      attr_reader :enforce_context

      def initialize
        reset!
      end

      # drop all model_space and model registrations. will cause any with_model_space_context
      # to most likely bork horribly
      def reset!
        @model_spaces = {}
        @model_spaces_by_models = {}
      end

      def register_model(model, model_space_name, opts={})
        old_ms = unchecked_get_model_space_for_model(model)
        old_ms.deregister_model(model) if old_ms

        new_ms = register_model_space(model_space_name).register_model(model, opts)
        register_model_space_for_model(model, new_ms)
      end

      def set_base_table_name(model, table_name)
        ms = unchecked_get_model_space_for_model(model)
        raise "model #{model} is not (yet) registered to a ModelSpace. do in_model_space before set_table_name or use the :base_table_name option of in_model_space" if !ms
        ms.set_base_table_name(model, table_name)
      end

      def base_table_name(model)
        get_model_space_for_model(model).base_table_name(model)
      end

      def set_enforce_context(v)
        @enforce_context = !!v
      end

      def table_name(model)
        ctx = enforce_context ? get_context_for_model(model) : unchecked_get_context_for_model(model)
        if ctx
          ctx.table_name(model)
        else
          get_model_space_for_model(model).base_table_name(model)
        end
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
      # only a single context can be active for a given ModelSpace on any Thread at
      # any time, though different ModelSpaces may have active contexts concurrently
      def with_model_space_context(model_space_name, model_space_key, &block)

        ms = get_model_space(model_space_name)
        raise "no such model space: #{model_space_name}" if !ms

        old_merged_context = self.send(:merged_context)
        ctx = ms.create_context(model_space_key)
        context_stack << ctx
        begin
          self.merged_context = merge_context_stack

          r = block.call
          ctx.commit
          r
        ensure
          context_stack.pop
          self.merged_context = old_merged_context
        end
      end

      private

      def register_model_space(model_space_name)
        model_spaces[model_space_name.to_sym] ||= ModelSpace.new(model_space_name.to_sym)
      end

      def get_model_space(model_space_name)
        model_spaces[model_space_name.to_sym]
      end

      def register_model_space_for_model(model, model_space)
        model_spaces_by_models[name_from_model(model)] = model_space
      end

      def unchecked_get_model_space_for_model(model)
        mc = all_model_superclasses(model).find do |klass|
          model_spaces_by_models[name_from_model(klass)]
        end
        model_spaces_by_models[name_from_model(mc)] if mc
      end

      def get_model_space_for_model(model)
        ms = unchecked_get_model_space_for_model(model)
        raise "model: #{model} is not registered to any ModelSpace" if !ms
        ms
      end

      CONTEXT_STACK_KEY = "ActiveRecord::ModelSpaces.context_stack"

      def context_stack
        Thread.current[CONTEXT_STACK_KEY] ||= []
      end

      MERGED_CONTEXT_KEY = "ActiveRecord::ModelSpaces.merged_context"

      def merged_context
        Thread.current[MERGED_CONTEXT_KEY] || {}
      end

      def merged_context=(mc)
        Thread.current[MERGED_CONTEXT_KEY] = mc
      end

      # merge all entries in the context stack into a map
      def merge_context_stack
        context_stack.reduce({}) do |m, ctx|
          raise "ModelSpace: #{ctx.model_space.name}: already has an active context" if m[ctx.model_space.name]
          m[ctx.model_space.name] = ctx
          m
        end
      end

      def unchecked_get_context_for_model(model)
        ms = unchecked_get_model_space_for_model(model)
        merged_context[ms.name] if ms
      end

      def get_context_for_model(model)
        ms = get_model_space_for_model(model)
        ctx = merged_context[ms.name]
        raise "ModelSpace: '#{ms.name}' has no current context" if !ctx
        ctx
      end
    end
  end
end
