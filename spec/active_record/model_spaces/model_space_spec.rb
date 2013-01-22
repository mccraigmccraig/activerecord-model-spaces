require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'active_record/model_spaces/model_space'
module ActiveRecord
  module ModelSpaces

    describe ModelSpace do

      describe "initialize" do

        it "should initialize with a name symbol" do
          ModelSpace.new(:foo).name.should == :foo
        end

        it "should convert a string name to a symbol" do
          ModelSpace.new("foo").name.should == :foo
        end

      end

      describe "register_model" do

        it "should register a model" do
          ms = ModelSpace.new(:foo)
          m = double("bar-model")

          r = ms.register_model(m)
          r.should == ms # registering a model returns the ModelSpace

          r.registered_models.include?(m).should == true
          r.history_versions(m).should == 0
        end

        it "should register a model with history_versions" do
          ms = ModelSpace.new(:foo)
          m = double("bar-model")

          r = ms.register_model(m, :history_versions=>3)
          r.should == ms # registering a model returns the ModelSpace

          r.registered_models.include?(m).should == true
          r.history_versions(m).should == 3
        end
      end

      describe "create_context" do

        it "should create a new context with a persistor" do

          p = double("persistor")
          ModelSpaces.should_receive(:create_persistor).with().and_return(p)

          ms = ModelSpace.new(:foo)

          ctx = double("context")
          Context.should_receive(:new).with(ms, "foofoo", p)

          ms.create_context("foofoo")
        end
      end

    end

    describe "create_persistor" do
      it "should create a persistor with the default connection and empty table-name" do
        c = double('connection')
        ActiveRecord::Base.should_receive(:connection).and_return(c)

        Persistor.should_receive(:new).with(c, nil)

        ModelSpaces.create_persistor.should == p
      end

      it "should create a persistor with a given connection and table-name" do
        c = double('connection')
        ModelSpaces.stub(:connection).and_return(c)
        ModelSpaces.stub(:table_name).and_return("foo_model_spaces")

        Persistor.should_receive(:new).with(c, "foo_model_spaces")

        ModelSpaces.create_persistor.should == p
      end
    end

    describe "check_model_registration_keys" do
      it "should accept the history_versions key" do
        expect {
          ModelSpaces.check_model_registration_keys([:history_versions])
        }.not_to raise_error
      end

      it "should not accept another key" do
        expect {
          ModelSpaces.check_model_registration_keys([:another_key])
        }.to raise_error "unknown keys: [:another_key]"
      end
    end

  end
end
