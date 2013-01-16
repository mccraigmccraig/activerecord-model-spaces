require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module ActiveRecord
  describe ModelSpaces do

    describe "MODEL_SPACES_REGISTRY" do
      it "should create a ModelSpace object if it doesn't exist" do
        ModelSpaces.register_model_space(:foo)
        ModelSpaces.get_model_space(:foo).should_not == nil
      end

      it "should register with a keyword name if a string is given" do
        ModelSpaces.register_model_space("foo")
        ms = ModelSpaces.get_model_space(:foo)
        ms.should_not == nil
        ms.name.should == :foo
        ModelSpaces.get_model_space("foo").should == ms
      end
    end

    describe "MODEL_REGISTRY" do
      it "should register a ModelSpace for a model" do
        ms = double('model-space')
        m = double('model')
        ModelSpaces.register_model(m , ms)
        ModelSpaces.get_model_space_for_model(m).should == ms
      end

      it "should bork if a model is registered twice" do
        ms = double('model-space')
        ms.stub(:name).and_return(:foo_space)
        ms2 = double('model-space-2')
        m = double('model')
        ModelSpaces.register_model(m , ms)

        expect {
          ModelSpaces.register_model(m, ms2)
        }.to raise_error /already registered to model space: foo_space/
      end
    end

    describe "merge_context_stack" do

      it "should merge contexts into a hash of contexts" do
        ms1 = double('model-space-1')
        ms1.stub(:name).and_return(:space_1)
        ctx1 = double('context-1')
        ctx1.stub(:model_space).and_return(ms1)

        ms2 = double('model-space-2')
        ms2.stub(:name).and_return(:space_2)
        ctx2 = double('context-2')
        ctx2.stub(:model_space).and_return(ms2)

        ModelSpaces.stub(:model_space_context_stack).and_return( [ctx1, ctx2] )

        ModelSpaces.merge_context_stack.should == {:space_1=>ctx1, :space_2=>ctx2}
      end
    end

  end
end
