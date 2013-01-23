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
          c.model_space_key.should == :one
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

        if attrs[:model_space_key]
          msk = attrs[:model_space_key]
        else
          msk = double('model-space-key')
          msk.stub(:to_sym).and_return(msk)
        end
        p = attrs[:persistor] || double('persistor')

        cmv = attrs[:current_model_versions] || double('current-model-versions')
        p.should_receive(:read_model_space_model_versions).with(ms_name, msk).and_return(cmv)

        Context.new(ms, msk, p)
      end

      def create_context_with_one_model(im, attrs={})
        im.stub(:to_s).and_return("Items")
        ms = ModelSpace.new(:foo)
        ms.register_model(im, :history_versions=>2)
        create_context(attrs.merge(:model_space=>ms, :current_model_versions=>{"Items"=>1}))
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
          im = double('items-model')
          ctx = create_context_with_one_model(im, :model_space_key=>"one")
          TableNames.should_receive(:table_name).with(:foo, :one, im, 2, 1)
          ctx.table_name(im)
        end

        it "should return the working_model_version based table_name if present" do
          im = double('items-model')
          ctx = create_context_with_one_model(im, :model_space_key=>"one")
          ctx.send(:set_working_model_version, im, 2)
          TableNames.should_receive(:table_name).with(:foo, :one, im, 2, 2)
          ctx.table_name(im)
        end
      end



      describe "table_name_from_model_version" do
        it "should call the TableNames.table_name method" do
          im = double('items-model')
          ctx = create_context_with_one_model(im, :model_space_key=>"one")

          v = double('version')
          TableNames.should_receive(:table_name).with(:foo, :one, im, 2, v)
          ctx.send(:table_name_from_model_version, im, v)

          TableNames.rspec_reset
          ctx.send(:table_name_from_model_version, im, 3).should == "foo__one__items__3"
          ctx.send(:table_name_from_model_version, im, 0).should == "foo__one__items"
          ctx.send(:table_name_from_model_version, im, nil).should == "foo__one__items"
        end
      end

      describe "get_current_model_version & set_working_model_version & get_working_model_version & delete_working_model_version" do
        it "should set and get the working model version" do
          im = double('items-model')
          ctx = create_context_with_one_model(im, :model_space_key=>"one")
          ctx.send(:get_current_model_version, im).should == 1

          ctx.send(:get_working_model_version, im).should == nil
          ctx.send(:set_working_model_version, im, 2)
          ctx.send(:get_working_model_version, im).should == 2
          ctx.send(:delete_working_model_version, im)
          ctx.send(:get_working_model_version, im).should == nil
        end
      end

    end
  end
end
