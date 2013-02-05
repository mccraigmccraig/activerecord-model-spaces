require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module ActiveRecord
  describe ModelSpaces do

    describe "with_context" do
      it "should pass with_context calls to the registry" do
        ModelSpaces::REGISTRY.should_receive(:with_context).and_return do |model_space_name, model_space_key, &block|
          model_space_name.should == :foo_space
          model_space_key.should == :one
          block.call
        end

        ModelSpaces.with_context(:foo_space, :one) do
          :result
        end.should == :result
      end
    end

    describe "kill_context" do
      it "should pass kill_context calls to the registry" do
        ModelSpaces::REGISTRY.should_receive(:kill_context).with(:foo_space, :one)
        ModelSpaces.kill_context(:foo_space, :one)
      end
    end

    describe "enforce_context" do
      it "should pass enforce_contrext calls to the registry" do
        ec = double('enforce-context')
        ModelSpaces::REGISTRY.should_receive(:enforce_context).and_return(ec)
        ModelSpaces.enforce_context.should == ec
      end
    end

    describe "set_enforce_context" do
      it "should pass set_enforce_context calls to the registry" do
        ec = double('enforce-context')
        ModelSpaces::REGISTRY.should_receive(:set_enforce_context).with(ec)
        ModelSpaces.set_enforce_context(ec)
      end
    end

    def create_model_spaces_class
      klass = Class.new
      klass.class_eval do
        include ActiveRecord::ModelSpaces
      end
      klass
    end

    it "should pass set_table_name calls to the registry" do
      klass = create_model_spaces_class
      ModelSpaces::REGISTRY.should_receive(:set_base_table_name).with(klass, "random_models")
      klass.set_table_name("random_models")
    end

    it "should pass table_name= calls to the registry" do
      klass = create_model_spaces_class
      ModelSpaces::REGISTRY.should_receive(:set_base_table_name).with(klass, "random_models")
      klass.table_name = "random_models"
    end

    it "should pass in_model_space calls to the registry" do
      klass = create_model_spaces_class
      ModelSpaces::REGISTRY.should_receive(:register_model).with(klass, :foo_space, {})
      klass.in_model_space :foo_space
    end

    it "should pass table_name calls to the registry" do
      klass = create_model_spaces_class
      ModelSpaces::REGISTRY.should_receive(:table_name).with(klass).and_return("foos")
      klass.table_name.should == "foos"
    end

    it "should pass current_table_name calls to the registry" do
      klass = create_model_spaces_class
      ModelSpaces::REGISTRY.should_receive(:current_table_name).with(klass).and_return("foos")
      klass.current_table_name.should == "foos"
    end

    it "should pass working_table_name calls to the registry" do
      klass = create_model_spaces_class
      ModelSpaces::REGISTRY.should_receive(:working_table_name).with(klass).and_return("foos")
      klass.working_table_name.should == "foos"
    end

    it "should pass new_version calls to the registry" do
      klass = create_model_spaces_class
      ModelSpaces::REGISTRY.should_receive(:new_version).with(klass).and_return do |k, &proc|
        proc.call.should == :blah
      end
      klass.new_version{:blah}
    end

    it "should pass updated_version calls to the registry" do
      klass = create_model_spaces_class
      ModelSpaces::REGISTRY.should_receive(:updated_version).with(klass).and_return do |k, &proc|
        proc.call.should == :blah
      end
      klass.updated_version{:blah}
    end

    it "should pass hoover calls to the registry" do
      klass = create_model_spaces_class
      ModelSpaces::REGISTRY.should_receive(:hoover).with(klass).and_return(true)
      klass.hoover
    end
  end
end
