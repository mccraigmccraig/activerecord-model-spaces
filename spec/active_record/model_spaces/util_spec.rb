require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'active_record'
require 'active_record/model_spaces/util'

module ActiveRecord
  module ModelSpaces

    describe Util do

      describe "name_from_model" do
        it "should stringify the model" do
          m = double('model')
          mk = double('model-key')
          m.should_receive(:to_s).and_return(mk)
          Util.name_from_model(m).should == mk
        end

      end

      describe "model_from_name" do
        it "should return the model class from the classname" do
          Util.model_from_name("ActiveRecord::ModelSpaces").should == ActiveRecord::ModelSpaces
        end

        it "should do nothing if given a model class" do
          Util.model_from_name(ActiveRecord::ModelSpaces).should == ActiveRecord::ModelSpaces
        end
      end

      describe "require_for_classname" do
        it "should require a file based on the classname then eval the classname to get the class" do
          Kernel.should_receive(:require).with('active_record/model_spaces/foo_table_schema_copier')
          klass = double('the-class')
          Kernel.should_receive(:eval).with("ActiveRecord::ModelSpaces::FooTableSchemaCopier").and_return(klass)
          Util.require_for_classname("ActiveRecord::ModelSpaces::FooTableSchemaCopier").should == klass
        end

        it "should return false in the case of any error" do
          Kernel.should_receive(:require).with('active_record/model_spaces/foo_table_schema_copier').and_return{raise "boo"}
          Util.require_for_classname("ActiveRecord::ModelSpaces::FooTableSchemaCopier").should == false
        end
      end

      describe "class_for_classname" do
        it "should eval a classname to get a class" do
          klass = double('the-class')
          Kernel.should_receive(:eval).with("ActiveRecord::ModelSpaces::FooTableSchemaCopier").and_return(klass)

          Util.class_for_classname("ActiveRecord::ModelSpaces::FooTableSchemaCopier").should == klass
        end

        it "should return false in the case of any error" do
          Kernel.should_receive(:eval).with("ActiveRecord::ModelSpaces::FooTableSchemaCopier").and_return{raise "boo"}
          Util.class_for_classname("ActiveRecord::ModelSpaces::FooTableSchemaCopier").should == false
        end
      end

      describe "class_from_classname" do
        it "should try class_for_classname then require_for_classname to find a class" do
          klass = double('the-class')

          Kernel.should_receive(:eval).with("ActiveRecord::ModelSpaces::FooTableSchemaCopier").and_return{raise "boo"}

          Kernel.should_receive(:require).with('active_record/model_spaces/foo_table_schema_copier').and_return do
            Kernel.rspec_reset
            Kernel.should_receive(:eval).with("ActiveRecord::ModelSpaces::FooTableSchemaCopier").and_return(klass)
          end

          Util.class_from_classname("ActiveRecord::ModelSpaces::FooTableSchemaCopier").should == klass
        end
      end

      describe "all_model_superclasses" do
        it "should return an ordered list of all model superclasses of a class" do
          c1 = Class.new(ActiveRecord::Base)
          c2 = Class.new(c1)
          c3 = Class.new(c2)

          Util.all_model_superclasses(c3).should == [c3,c2,c1]
        end
      end

      describe "is_active_record_model?" do
        it "should return true for direct or indirect subclasses of ActiveRecord::Base" do
          c1 = Class.new(ActiveRecord::Base)
          Util.is_active_record_model?(c1).should == true

          c2 = Class.new(c1)
          Util.is_active_record_model?(c2).should ==true
        end

        it "should return false for non-subclasses of ActiveRecord::Base" do
          Util.is_active_record_model?(ActiveRecord::Base).should == false

          c1 = Class.new
          Util.is_active_record_model?(c1).should == false

          c2 = Class.new
          Util.is_active_record_model?(c2).should == false
        end
      end

    end
  end
end
