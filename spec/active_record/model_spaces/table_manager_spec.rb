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

        it "should initialize with a model name" do
          c = double('connection')
          ActiveRecord::ModelSpaces.should_receive(:connection).and_return(c)
          tm = TableManager.new("ActiveRecord::ModelSpaces")
          tm.model.should == ActiveRecord::ModelSpaces
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

          tsc = double('table-schema-copier')
          tm.should_receive(:get_table_schema_copier).with(tm.connection).and_return(tsc)

          tsc.should_receive(:copy_table_schema).with(tm.connection, 'foos', 'bars')

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

      describe "get_table_schema_copier" do
        it "should get a TableSchemaCopier specialised for the connection adapter, if available" do
          c = double('connection')
          c.stub(:adapter_name)
        end

        it "should get a DefaultTableSchemaCopier if no specialised TableSchemaCopier available" do

        end
      end

      describe MySQLTableSchemaCopier do

        describe "copy_table_schema" do
          it "should ask mysql for the create-table statement, modify it and execute the modified statement" do
            c = double('connection')
            c.should_receive(:select_rows).with("SHOW CREATE TABLE `foos`").and_return([["foos", "CREATE TABLE `foos` (blah)"]])
            c.should_receive(:execute).with("CREATE TABLE `bars` (blah)")

            MySQLTableSchemaCopier.copy_table_schema(c, "foos", "bars")
          end
        end

        describe "table_schema" do
          it "should ask mysql for the create-table statement for the table" do
            c = double('connection')
            c.should_receive(:select_rows).with("SHOW CREATE TABLE `foos`").and_return([["foos", "CREATE TABLE `foos` (blah)"]])
            MySQLTableSchemaCopier.table_schema(c, "foos").should == "CREATE TABLE `foos` (blah)"
          end
        end

        describe "change_table_name" do
          it "should change the table name in the CREATE TABLE statement" do
            MySQLTableSchemaCopier.change_table_name('foos', 'bars', "CREATE TABLE `foos` (blah)").should ==
              "CREATE TABLE `bars` (blah)"
          end
        end

      end

      describe DefaultTableSchemaCopier do

        describe "copy_table_schema" do
          it "should extract ruby schema, modify and eval it to create a new table"  do
            c = double('connection')
            c.should_receive(:instance_eval).with('create_table "bars" ()')

            DefaultTableSchemaCopier.should_receive(:table_schema).with(c, "foos").and_return('create_table "foos" ()')

            DefaultTableSchemaCopier.copy_table_schema(c, "foos", "bars")
          end
        end

        describe "table_schema" do
          it "should use the schema dumper to retrieve ruby code to create a table" do
            c = double('connection')

            sd = double('schema-dumper')
            ActiveRecord::SchemaDumper.should_receive(:new).with(c).and_return(sd)

            sd.should_receive(:table).with('foos', anything).and_return(StringIO.new('create_table "foos" ()'))

            DefaultTableSchemaCopier.table_schema(c, "foos").should == 'create_table "foos" ()'
          end
        end

        describe "change_table_name" do
          it "should alter the provided schema generating code to change the table_name" do
            tm = create_table_manager
            DefaultTableSchemaCopier.change_table_name( "foos", "bars", 'create_table "foos" (blahblah)\nadd_index "foos" blahblah').should ==
              'create_table "bars" (blahblah)\nadd_index "bars" blahblah'
          end
        end

      end
    end
  end
end
