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
          m.stub(:to_s).and_return("BarModel")

          r = ms.register_model(m)
          r.should == ms # registering a model returns the ModelSpace

          r.registered_model_keys.include?("BarModel").should == true
          r.history_versions(m).should == 0
        end

        it "should register a model with history_versions" do
          ms = ModelSpace.new(:foo)
          m = double("bar-model")
          m.stub(:to_s).and_return("BarModel")

          r = ms.register_model(m, :history_versions=>3)
          r.should == ms # registering a model returns the ModelSpace

          r.registered_model_keys.include?("BarModel").should == true
          r.history_versions(m).should == 3
        end

        it "should register a model with a base_table_name" do
          ms = ModelSpace.new(:foo)
          m = double("bar-model")
          m.stub(:to_s).and_return("BarModel")

          r = ms.register_model(m, :base_table_name=>"a_random_name")
          r.should == ms # registering a model returns the ModelSpace

          r.registered_model_keys.include?("BarModel").should == true
          r.base_table_name(m).should == "a_random_name"
        end
      end

      describe "is_registered?" do
        it "should return true if a model is registered, false otherwise" do
          ms = ModelSpace.new(:foo)
          m = double('bar-model')
          m.stub(:to_s).and_return("BarModel")

          m2 = double('baz-model')
          m2.stub(:to_s).and_return('BazModel')

          ms.register_model(m)
          ms.is_registered?(m).should == true

          ms.is_registered?(m2).should == false
        end
      end

      describe "history_versions" do
        it "should return 0 if no history_versions were specified" do
          ms = ModelSpace.new(:foo)
          m = double("bar-model")
          m.stub(:to_s).and_return("BarModel")

          r = ms.register_model(m)
          r.should == ms # registering a model returns the ModelSpace

          r.registered_model_keys.include?("BarModel").should == true
          r.history_versions(m).should == 0
        end
      end

      describe "base_table_name" do
        it "should use TableNames.base_table_name to determine the base_table_name if non is specified" do
          ms = ModelSpace.new(:foo)
          m = double("bar-model")
          m.stub(:to_s).and_return("BarModel")

          r = ms.register_model(m)
          r.should == ms # registering a model returns the ModelSpace

          r.registered_model_keys.include?("BarModel").should == true
          r.base_table_name(m).should == "bar_models"
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
