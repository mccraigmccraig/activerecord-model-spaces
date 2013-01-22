require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'active_record/model_spaces/context'

module ActiveRecord
  module ModelSpaces

    describe Context do

      describe "initialize" do

        it "should initialize with a model_space, model_space_key and persistor" do
          ms = double('model-space')
          ms.stub(:name).and_return('foo_space')

          p = double('persistor')
          v = {"Items"=>1, "Users"=>2}
          p.should_receive(:read_model_space_model_versions).with('foo_space', 'one').and_return(v)

          c = Context.new(ms, 'one', p)
          c.model_space.should == ms
          c.model_space_key.should == 'one'
          c.persistor.should == p
          c.current_model_versions.should == {"Items"=>1, "Users"=>2}
          c.working_model_versions.should == {}
        end
      end

      def create_context(attrs = {})
        ms = attrs[:model_space] || double('model-space')

        if attrs[:model_space]
          ms_name = attrs[:model_space].name
        else
          ms_name = double('model-space-name')
          ms.stub(:name).and_return(ms_name)
        end

        msk = attrs[:model_space_key] || double('model-space-key')
        p = attrs[:persistor] || double('persistor')

        cmv = attrs[:current_model_versions] || double('current-model-versions')
        p.should_receive(:read_model_space_model_versions).with(ms_name, msk).and_return(cmv)

        Context.new(ms, msk, p)
      end

      describe "base_table_name" do
        it "should return the base table_name" do
          ctx = create_context

          m = double('model')
          TableNames.should_receive(:base_table_name).with(m)

          ctx.base_table_name(m)
        end
      end

      describe "table_name" do
        it "should return the current_model_version based table_name if present" do
          ctx = create_context(:current_model_versions=>{"Users"=>2})

          m = double('model')
#

        end

        it "should return the working_model_version based table_name if present" do

        end
      end
    end
  end
end
