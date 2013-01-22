require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'active_support/core_ext/class' # SchemaDumper needs this

require 'active_record/model_spaces/table_manager'

module ActiveRecord
  module ModelSpaces

    describe TableManager do

      describe "initialize" do
        it "should initialize with a model" do
          m = double('model')
          c = double('connection')
          m.should_receive(:connection).and_return(c)
          tm = TableManager.new(m)
          tm.model.should == m
          tm.connection.should == c
        end
      end

      def create_table_manager(model=nil)
        model ||= double('model')
        connection = double('connection')
        model.stub(:connection).and_return(connection)
        TableManager.new(model)
      end

      describe "create table" do
        it "should extract the base_table schema, and use it to create a new table" do
          tm = create_table_manager
          bts = double('base-table-schema')
          tm.should_receive(:table_schema).and_return(bts)
          ts = double('table-schema')
          tm.should_receive(:change_table_name).with('foos', 'bars', bts).and_return(ts)
          tm.connection.should_receive(:instance_eval).with(ts)

          tm.create_table('foos', 'bars')
        end
      end

      describe "drop table" do
        it "should drop the given table if it exists" do
          tm = create_table_manager
          tm.connection.should_receive(:table_exists?).with("foos").and_return(true)
          tm.connection.should_receive(:execute).with("drop table foos")
          tm.drop_table("foos")
        end

        it "should do nothing if the given table does not exist" do
          tm = create_table_manager
          tm.connection.should_receive(:table_exists?).with("foos").and_return(false)
          tm.drop_table("foos")
        end
      end

      describe "recreate table" do
        it "should drop the table if it exists, and recreate it from the base table if the table_name is different from the base_table_name" do
          tm = create_table_manager
          tm.should_receive(:drop_table).with("bars")
          tm.should_receive(:create_table).with("foos", "bars")
          tm.recreate_table("foos", "bars")
        end

        it "should do nothing if the base_table_name is the same as the table_name" do
          tm = create_table_manager
          tm.recreate_table("foos", "foos")
        end
      end

      describe "truncate table" do
        it "should truncate the given table" do
          tm = create_table_manager
          tm.connection.should_receive(:execute).with("truncate table foos")
          tm.truncate_table('foos')
        end
      end

      describe "copy table" do
        it "should copy data from the source to the target table if source and target are different" do
          tm = create_table_manager
          tm.connection.should_receive(:execute).with("insert into bars select * from foos")
          tm.copy_table('foos', 'bars')
        end

        it "should do nothing if source and target are the same" do
          tm = create_table_manager
          tm.copy_table('foos', 'foos')
        end
      end

      describe "table_schema" do
        it "should use the schema dumper to retrieve ruby code to create a table" do
          tm = create_table_manager

          sd = double('schema-dumper')
          ActiveRecord::SchemaDumper.should_receive(:new).with(tm.connection).and_return(sd)

          sd.should_receive(:table).with('foos', anything).and_return(StringIO.new('create_table "foos" ()'))

          tm.send(:table_schema, "foos").should == 'create_table "foos" ()'
        end
      end

      describe "change_table_name" do
        it "should alter the provided schema generating code to change the table_name" do
          tm = create_table_manager
          tm.send(:change_table_name, "foos", "bars", 'create_table "foos" (blahblah)\nadd_index "foos" blahblah').should ==
            'create_table "bars" (blahblah)\nadd_index "bars" blahblah'
        end
      end
    end
  end
end
