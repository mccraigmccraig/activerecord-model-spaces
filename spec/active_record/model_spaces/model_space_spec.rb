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

          reg = ms.model_registrations[m]
          reg.model_space.should == ms
          reg.model.should == m
          reg.history_versions.should == 0
        end
      end

      describe "create_context" do

        it "should create a new context with a persistor and the default connection" do

          dc = double("default-connection")
          ActiveRecord::Base.stub(:connection).and_return(dc)

          p = double("persistor")
          ModelSpaces.should_receive(:create_persistor).with(dc).and_return(p)

          ms = ModelSpace.new(:foo)

          ctx = double("context")
          Context.should_receive(:new).with(ms, "foofoo", p)

          ms.create_context("foofoo")
        end

        it "should create a new context with a persistor and another connection" do
          c = double("the-connection")
          ModelSpaces.stub(:connection).and_return(c)

          p = double("persistor")
          ModelSpaces.should_receive(:create_persistor).with(c).and_return(p)

          ms = ModelSpace.new(:foo)

          ctx = double("context")
          Context.should_receive(:new).with(ms, "foofoo", p)

          ms.create_context("foofoo")

        end
      end

    end

    describe "create_persistor" do
      it "should require the persistor definition file if the persistor class is not yet defined" do
        pc = double("persistor-class")
        Kernel.should_receive(:require).with("active_record/model_spaces/foo_persistor").and_return do
          stub_const("ActiveRecord::ModelSpaces::FooPersistor", pc)
          pc
        end

        c = double("connection")
        c.should_receive(:adapter_name).and_return("Foo")
        ModelSpaces.stub(:table_name).and_return("foo_model_space_tables")

        p = double("persistor")
        pc.should_receive(:new).with(c, "foo_model_space_tables").and_return(p)

        ModelSpaces.create_persistor(c).should == p
      end
    end

    describe "create_table_manager" do
      it "should require the table manager definition file if the table manager is not yet defined" do
        tmc = double("table-manager-class")
        Kernel.should_receive(:require).with("active_record/model_spaces/foo_table_manager").and_return do
          stub_const("ActiveRecord::ModelSpaces::FooTableManager", tmc)
          tmc
        end

        tm = double("table-manager")
        tmc.should_receive(:new).and_return(tm)

        ModelSpaces.create_table_manager("Foo").should == tm
      end
    end


  end
end
