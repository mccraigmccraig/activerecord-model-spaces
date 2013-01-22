require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module ActiveRecord
  describe ModelSpaces do

    def create_model_spaces_class
      klass = Class.new
      class << klass
        include ActiveRecord::ModelSpaces
      end
      klass
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
