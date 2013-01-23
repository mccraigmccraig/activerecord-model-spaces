require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

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

    end
  end
end
