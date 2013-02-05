require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'active_record/model_spaces/context'

module ActiveRecord
  module ModelSpaces

    describe Context do

      def create_model(name, superklass=ActiveRecord::Base)
        m = Class.new(superklass)
        m.stub(:to_s).and_return(name)
        m.stub(:inspect).and_return(name)
        m
      end


      describe "initialize" do

        it "should initialize with a model_space, model_space_key and persistor and create necessary tables" do
          im = create_model('Items')
          um = create_model('Users')

          ms = ModelSpace.new(:foo_space)
          ms.register_model(im)
          ms.register_model(um)

          Util.stub(:model_from_name).with("Items").and_return(im)
          Util.stub(:model_from_name).with("Users").and_return(um)

          itm = double('items-table-manager')
          utm = double('users-table-manager')
          TableManager.should_receive(:new).with(im).and_return(itm)
          TableManager.should_receive(:new).with(um).and_return(utm)

          itm.should_receive(:create_table).with("items", "foo_space__one__items__1")
          utm.should_receive(:create_table).with("users", "foo_space__one__users__2")

          p = double('persistor')
          v = {"Items"=>1, "Users"=>2}
          p.should_receive(:read_model_space_model_versions).with(:foo_space, :one).and_return(v)

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
          msk = attrs[:model_space_key].to_sym
        else
          msk = double('model-space-key')
          msk.stub(:to_sym).and_return(msk)
        end
        p = attrs[:persistor] || double('persistor')

        cmv = attrs[:current_model_versions] || double('current-model-versions')
        p.should_receive(:read_model_space_model_versions).with(ms_name, msk).and_return(cmv)

        Context.any_instance.stub(:create_tables) # don't need this here
        Context.new(ms, msk, p)
      end

      def create_context_with_one_model(attrs={})
        im = create_model('Item')
        ms = ModelSpace.new(:foo)
        ms.register_model(im, :history_versions=>2, :base_table_name=>"some_items")
        ctx = create_context(attrs.merge(:model_space=>ms, :current_model_versions=>{"Item"=>1}))
        [ctx, im]
      end

      def create_context_with_parent_child_models(attrs={})
        p = create_model('Parent')
        c = create_model('Child', p)
        ms = ModelSpace.new(:foo)
        ms.register_model(p, :history_versions=>2)
        ctx = create_context(attrs.merge(:model_space=>ms, :current_model_versions=>{"Parent"=>1}))
        [ctx, p, c]
      end

      def create_context_with_two_models(attrs={})
        im = create_model('Item')
        um = create_model('User')
        ms = ModelSpace.new(:foo)
        ms.register_model(im, :history_versions=>2)
        ms.register_model(um, :history_versions=>1)
        ctx = create_context(attrs.merge(:model_space=>ms, :current_model_versions=>{"Item"=>1}))
        [ctx, im, um]
      end

      def create_context_with_three_models(attrs={})
        im = create_model('Item')
        um = create_model('User')
        om = create_model('Other')
        ms = ModelSpace.new(:foo)
        ms.register_model(im, :history_versions=>2)
        ms.register_model(um, :history_versions=>1)
        ms.register_model(om, :history_versions=>0)
        ctx = create_context(attrs.merge(:model_space=>ms, :current_model_versions=>{"Item"=>1}))
        [ctx, im, um, om]
      end

      describe "base_table_name" do
        it "should ask the ModelSpace for the base_table_name" do
          ctx, m = create_context_with_one_model
          ctx.model_space.should_receive(:base_table_name).with(m)
          ctx.base_table_name(m)
        end
      end

      describe "table_name" do
        it "should return the current_model_version based table_name if present" do
          ctx, im = create_context_with_one_model(:model_space_key=>"one")
          TableNames.should_receive(:table_name).with(:foo, :one, "some_items", 2, 1)
          ctx.table_name(im)
        end

        it "should return the working_model_version based table_name if present" do
          ctx,im = create_context_with_one_model(:model_space_key=>"one")
          ctx.send(:set_working_model_version, im, 2)
          TableNames.should_receive(:table_name).with(:foo, :one, "some_items", 2, 2)
          ctx.table_name(im)
        end
      end

      describe "hoovered_table_name" do
        it "should return the table_name for the model with version 0" do
          ctx,im = create_context_with_one_model(:model_space_key=>"one")
          TableNames.should_receive(:table_name).with(:foo, :one, "some_items", 2, 0)
          ctx.hoovered_table_name(im)
        end
      end

      describe "current_table_name" do
        it "should return the current_model_version based table_name" do
          ctx,im = create_context_with_one_model(:model_space_key=>"one")
          ctx.should_receive(:table_name_from_model_version).with(im, 1)
          ctx.current_table_name(im)

          ctx.rspec_reset
          ctx.send(:set_working_model_version, im, 2)
          ctx.should_receive(:table_name_from_model_version).with(im,1)
          ctx.current_table_name(im)
        end
      end

      describe "next_table_name" do
        it "should return the next version based table_name" do
          ctx,im = create_context_with_one_model(:model_space_key=>"one")
          ctx.should_receive(:table_name_from_model_version).with(im, 2)
          ctx.next_table_name(im)

          ctx.rspec_reset
          ctx.send(:set_working_model_version, im, 2)
          ctx.should_receive(:table_name_from_model_version).with(im,2)
          ctx.next_table_name(im)
        end
      end

      describe "working_table_name" do
        it "should return the next version based table name or nil if no working version has been registered " do
          ctx,im = create_context_with_one_model(:model_space_key=>"one")
          ctx.working_table_name(im).should == nil

          ctx.rspec_reset
          ctx.send(:set_working_model_version, im, 2)
          ctx.should_receive(:table_name_from_model_version).with(im,2)
          ctx.next_table_name(im)
        end
      end

      describe "new_version" do
        it "should just call the block if the model already has a working version" do
          ctx,im = create_context_with_one_model(:model_space_key=>"one")
          ctx.send(:set_working_model_version, im, 2)
          ctx.send(:get_current_model_version, im).should == 1
          ctx.send(:get_working_model_version, im).should == 2

          TableManager.should_not_receive(:new)

          r = ctx.new_version(im){ :result }
          r.should == :result
        end

        it "should truncate the table and call the block if the model has no history versions and !copy_old_version" do
          ctx, im, um, om = create_context_with_three_models(:model_space_key=>"one")

          tm = double('table-manager')
          TableManager.stub(:new).and_return(tm)
          tm.should_receive(:truncate_table).with("foo__one__others")

          r = ctx.new_version(om){ :result }
          r.should == :result
        end

        it "should just call the block if the model has no history versions and copy_old_version" do
          ctx, im, um, om = create_context_with_three_models(:model_space_key=>"one")

          tm = double('table-manager')
          TableManager.stub(:new).and_return(tm)

          r = ctx.new_version(om, true){ :result }
          r.should == :result
        end

        it "should recreate the next_version table, set the working version and call the block if !copy_old_version" do
          ctx, im, um, om = create_context_with_three_models(:model_space_key=>"one")

          imtm = double('im-table-manager')
          TableManager.stub(:new).with(im).and_return(imtm)
          imtm.should_receive(:recreate_table).with('items', 'foo__one__items__2')

          umtm = double('um-table-manager')
          TableManager.stub(:new).with(um).and_return(umtm)
          umtm.should_receive(:recreate_table).with('users', 'foo__one__users__1')

          omtm = double('om-table-manager')
          TableManager.stub(:new).with(om).and_return(omtm)
          omtm.should_receive(:truncate_table).with('foo__one__others')

          ctx.table_name(im).should == 'foo__one__items__1'
          ctx.new_version(im){:result}.should == :result
          ctx.send(:get_working_model_version, im).should == 2
          ctx.table_name(im).should == 'foo__one__items__2'

          ctx.table_name(um).should == 'foo__one__users'
          ctx.new_version(um){:um_result}.should == :um_result
          ctx.send(:get_working_model_version, um).should == 1
          ctx.table_name(um).should == 'foo__one__users__1'

          ctx.table_name(om).should == 'foo__one__others'
          ctx.new_version(om){:om_result}.should == :om_result
          ctx.send(:get_working_model_version, om).should == 0
          ctx.table_name(om).should == 'foo__one__others'
        end

        it "should recreate the next_version table, set the working version, copy the previous version data and call the block if copy_old_version" do
          ctx, im, um, om = create_context_with_three_models(:model_space_key=>"one")

          imtm = double('im-table-manager')
          TableManager.stub(:new).with(im).and_return(imtm)
          imtm.should_receive(:recreate_table).with('items', 'foo__one__items__2')
          imtm.should_receive(:copy_table).with('foo__one__items__1', 'foo__one__items__2')

          umtm = double('um-table-manager')
          TableManager.stub(:new).with(um).and_return(umtm)
          umtm.should_receive(:recreate_table).with('users', 'foo__one__users__1')
          umtm.should_receive(:copy_table).with('foo__one__users', 'foo__one__users__1')

          omtm = double('om-table-manager')
          TableManager.stub(:new).with(om).and_return(omtm)
          omtm.should_not_receive(:truncate_table)

          ctx.table_name(im).should == 'foo__one__items__1'
          ctx.new_version(im, true){:result}.should == :result
          ctx.send(:get_working_model_version, im).should == 2
          ctx.table_name(im).should == 'foo__one__items__2'

          ctx.table_name(um).should == 'foo__one__users'
          ctx.new_version(um, true){:um_result}.should == :um_result
          ctx.send(:get_working_model_version, um).should == 1
          ctx.table_name(um).should == 'foo__one__users__1'

          ctx.table_name(om).should == 'foo__one__others'
          ctx.new_version(om, true){:om_result}.should == :om_result
          ctx.send(:get_working_model_version, om).should == 0
          ctx.table_name(om).should == 'foo__one__others'
        end

        it "should remove the working version if the supplied block borks" do
          ctx, im, um, om = create_context_with_three_models(:model_space_key=>"one")

          imtm = double('im-table-manager')
          TableManager.stub(:new).with(im).and_return(imtm)
          imtm.should_receive(:recreate_table).with('items', 'foo__one__items__2')

          ctx.table_name(im).should == 'foo__one__items__1'
          expect{
            ctx.new_version(im){raise "blah"}
          }.to raise_error /blah/
          ctx.table_name(im).should == 'foo__one__items__1'

        end

        it "should bork if a block is not supplied" do
          ctx, im = create_context_with_one_model(:model_space_key=>"one")

          expect {
            ctx.new_version(im)
          }.to raise_error /a block must be supplied/
        end
      end

      describe "hoover" do
        it "should bork if there are any working versions" do
          ctx, im = create_context_with_one_model(:model_space_key=>"one")
          ctx.send(:set_working_model_version, im, 2)

          expect {
            ctx.hoover
          }.to raise_error /can\'t hoover with active working versions/
        end

        it "should copy models to their base table, drop history tables and re-read model-versions" do
          ctx, im, um, om = create_context_with_three_models(:model_space_key=>"one")

          Util.stub(:model_from_name).with("Item").and_return(im)
          Util.stub(:model_from_name).with("User").and_return(um)
          Util.stub(:model_from_name).with("Other").and_return(om)

          imtm = double('im-table-manager')
          TableManager.stub(:new).with(im).and_return(imtm)
          TableManager.stub(:new).with("Item").and_return(imtm)
          imtm.should_receive(:recreate_table).with('items', 'foo__one__items')
          imtm.should_receive(:copy_table).with('foo__one__items__1', 'foo__one__items')
          imtm.should_receive(:drop_table).with('foo__one__items__1')
          imtm.should_receive(:drop_table).with('foo__one__items__2')

          umtm = double('um-table-manager')
          TableManager.stub(:new).with(um).and_return(umtm)
          TableManager.stub(:new).with("User").and_return(umtm)
          umtm.should_receive(:drop_table).with('foo__one__users__1')

          omtm = double('om-table-manager')
          TableManager.stub(:new).with(om).and_return(omtm)
          TableManager.stub(:new).with("Other").and_return(omtm)

          ctx.persistor.should_receive(:update_model_space_model_versions).with("Item"=>0, "User"=>0, "Other"=>0)
          ctx.should_receive(:read_versions)


          ctx.hoover

        end
      end

      describe "updated_version" do
        it "should call new_version with the copy_old_version flat set to true returning the result of the block" do
          ctx, im = create_context_with_one_model(:model_space_key=>"one")

          ctx.should_receive(:new_version).and_return do |model, copy_old_version, &block|
            model.should == im
            copy_old_version.should == true
            block.call
          end

          ctx.updated_version(im) { :result }.should == :result
        end
      end

      describe "commit" do
        it "should call the persistor with the merge of the current and working model versions" do
          ctx, im, um = create_context_with_two_models(:model_space_key=>"one")
          ctx.send(:set_working_model_version, um, 1)

          ctx.persistor.should_receive(:update_model_space_model_versions).with(ctx.model_space.name, :one, {"Item"=>1, "User"=>1})

          ctx.commit
        end
      end

      describe "table_name_from_model_version" do
        it "should call the TableNames.table_name method" do
          ctx, im = create_context_with_one_model(:model_space_key=>"one")

          v = double('version')
          TableNames.should_receive(:table_name).with(:foo, :one, "some_items", 2, v)
          ctx.send(:table_name_from_model_version, im, v)

          TableNames.rspec_reset
          ctx.send(:table_name_from_model_version, im, 3).should == "foo__one__some_items__3"
          ctx.send(:table_name_from_model_version, im, 0).should == "foo__one__some_items"
          ctx.send(:table_name_from_model_version, im, nil).should == "foo__one__some_items"
        end

        it "should call the TableNames.table_name method with registered superclass values" do
          ctx, p, c = create_context_with_parent_child_models(:model_space_key=>"one")
          v = double('version')
          TableNames.should_receive(:table_name).with(:foo, :one, "parents", 2, v)
          ctx.send(:table_name_from_model_version, c, v)
        end
      end

      describe "get_current_model_version & set_working_model_version & get_working_model_version & delete_working_model_version" do
        it "should set and get the working model version" do
          ctx, im = create_context_with_one_model(:model_space_key=>"one")
          ctx.send(:get_current_model_version, im).should == 1

          ctx.send(:get_working_model_version, im).should == nil
          ctx.send(:set_working_model_version, im, 2)
          ctx.send(:get_working_model_version, im).should == 2
          ctx.send(:delete_working_model_version, im)
          ctx.send(:get_working_model_version, im).should == nil
        end

        it "should set and get working model versions using the registered superclass" do
          ctx, p, c = create_context_with_parent_child_models(:model_space_key=>"one")

          ctx.send(:get_current_model_version, p).should == 1
          ctx.send(:get_current_model_version, c).should == 1

          ctx.send(:get_working_model_version, p).should == nil
          ctx.send(:get_working_model_version, c).should == nil

          ctx.send(:set_working_model_version, c, 2)

          ctx.send(:get_working_model_version, p).should == 2
          ctx.send(:get_working_model_version, c).should == 2

          ctx.send(:delete_working_model_version, c)

          ctx.send(:get_working_model_version, p).should == nil
          ctx.send(:get_working_model_version, c).should == nil
        end

        it "should bork if called with an unregistered model" do
          ctx, im = create_context_with_one_model(:model_space_key=>"one")

          rm = create_model('Random')

          expect {
            ctx.send(:get_current_model_version, rm)
          }.to raise_error /not registered with ModelSpace/

          expect {
            ctx.send(:get_working_model_version, rm)
          }.to raise_error /not registered with ModelSpace/

        end
      end

    end
  end
end
