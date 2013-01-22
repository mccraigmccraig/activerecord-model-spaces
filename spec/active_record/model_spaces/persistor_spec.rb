require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'active_record/model_spaces/persistor'

module ActiveRecord
  module ModelSpaces

    describe Persistor do

      def create_persistor(connection, table_name)
        Persistor.any_instance.should_receive(:create_model_spaces_table)
        Persistor.new(connection, table_name)
      end

      describe "initialize" do
        it "should initialize with a connection and default table_name" do
          c = double('connection')
          p = create_persistor(c, nil)
          p.connection.should == c
          p.table_name.should == "model_spaces_tables"
        end

        it "should initialize with a connection and table_name" do
          c = double('connection')
          p = create_persistor(c, "foo_model_spaces_tables")
          p.connection.should == c
          p.table_name.should == "foo_model_spaces_tables"
        end
      end

      describe "list_keys" do
        it "should query the connection for a list of prefixes for a model_space" do
          c = double('connection')

          c.should_receive(:select_rows).with("select model_space_key from ms_tables where model_space_name='blah'").and_return([["foo"], ["bar"]])

          p = create_persistor(c, "ms_tables")
          p.list_keys('blah').should == ["foo", "bar"]
        end
      end

      describe "read_model_space_model_versions" do
        it "should query the connection for model_space model_versions" do
          c = double('connection')

          c.should_receive(:select_all).with("select model_name, version from ms_tables where model_space_name='blah' and model_space_key='one'").and_return([{"model_name"=>"Users", "version"=>"1"}, {"model_name"=>"Items", "version"=>"0"}])

          p = create_persistor(c, 'ms_tables')
          p.read_model_space_model_versions('blah', 'one').should == {"Users"=>1, "Items"=>0}
        end
      end

      describe "update_model_space_model_versions" do
        it "should update model_version" do
          ActiveRecord::Base.stub(:transaction).and_return {|&block| block.call}

          c = double('connection')
          c.should_receive(:execute).with("update ms_tables set version=2 where model_space_name='blah' and model_space_key='one' and model_name='Foo'")
          c.should_receive(:execute).with("insert into ms_tables (model_space_name, model_space_key, model_name, version) values ('blah', 'one', 'Bar', 1)")
          c.should_receive(:execute).with("delete from ms_tables where model_space_name='blah' and model_space_key='one' and model_name='Baz'")

          p = create_persistor(c, 'ms_tables')

          p.should_receive(:read_model_space_model_versions).with('blah', 'one').and_return("Foo"=>1, "Baz"=>2, "Blah"=>1)

          p.update_model_space_model_versions('blah', 'one', "Foo"=>2, "Bar"=>1, "Baz"=>0, "Blah"=>1)
        end
      end

      describe "create_model_spaces_table" do
        it "should not issue migration statements against the connection if the persistor table exists" do
          c = double('connection')
          c.should_receive(:table_exists?).with("foo_table").and_return(true)
          p = Persistor.new(c, "foo_table")
        end

        it "should issue migration statements against the connection if the persistor table does not exist" do
          c = double('connection')
          c.should_receive(:table_exists?).with("foo_table").and_return(false)

          c.should_receive(:create_table).and_return do |table_name, &block|
            table_name.should == "foo_table"

            t = double("table")
            t.should_receive(:string).with(:model_space_name, :null=>false)
            t.should_receive(:string).with(:model_space_key, :null=>false)
            t.should_receive(:string).with(:model_name, :null=>false)
            t.should_receive(:integer).with(:version, :null=>false, :default=>0)

            block.call(t)
          end

          c.should_receive(:add_index).with("foo_table", [:model_space_name, :prefix, :model_name], :unique=>true)

          p = Persistor.new(c, "foo_table")
        end

      end
    end
  end
end
