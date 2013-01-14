require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'active_record/model_spaces/table_names'
module ActiveRecord
  module ModelSpaces
    describe TableNames do

      describe "base_table_name" do
        it "should underscore and pluralize the classname" do
          TableNames.base_table_name("FooBar").should == "foo_bars"
        end
      end

      describe "model_space_table_name" do
        it "should return base table-name if no model-space given" do
          TableNames.model_space_table_name("FooBar", nil).should == "foo_bars"
        end

        it "should return base table-name if an empty model-space given" do
          TableNames.model_space_table_name("FooBar", "").should == "foo_bars"
        end

        it "should prefix a model-space if given" do
          TableNames.model_space_table_name("FooBar", "blarghl").should == "blarghl__foo_bars"
        end
      end

      describe "table_name" do
        it "should do nothing if history versions is nil" do
          TableNames.table_name("FooBar", "blarghl", nil, 1).should == "blarghl__foo_bars"
        end

        it "should suffix version if history_versions is not nil" do
          TableNames.table_name("FooBar", "blarghl", nil, nil).should == "blarghl__foo_bars"
          TableNames.table_name("FooBar", "blarghl", 0, nil).should == "blarghl__foo_bars"
          TableNames.table_name("FooBar", "blarghl", 0, 1).should == "blarghl__foo_bars"

          TableNames.table_name("FooBar", "blarghl", 1, 0).should == "blarghl__foo_bars"
          TableNames.table_name("FooBar", "blarghl", 1, 1).should == "blarghl__foo_bars__1"
          TableNames.table_name("FooBar", "blarghl", 1, 2).should == "blarghl__foo_bars"
          TableNames.table_name("FooBar", "blarghl", 1, 3).should == "blarghl__foo_bars__1"

          TableNames.table_name("FooBar", "blarghl", 2, 0).should == "blarghl__foo_bars"
          TableNames.table_name("FooBar", "blarghl", 2, 1).should == "blarghl__foo_bars__1"
          TableNames.table_name("FooBar", "blarghl", 2, 2).should == "blarghl__foo_bars__2"
          TableNames.table_name("FooBar", "blarghl", 2, 3).should == "blarghl__foo_bars"
          TableNames.table_name("FooBar", "blarghl", 2, 4).should == "blarghl__foo_bars__1"
        end
      end

      describe "next_version" do
        it "should return the next version" do
          TableNames.next_version(nil, nil).should == 0

          TableNames.next_version(0, nil).should == 0
          TableNames.next_version(0, 1).should == 0

          TableNames.next_version(1, nil).should == 1
          TableNames.next_version(1, 0).should == 1
          TableNames.next_version(1, 1).should == 0
          TableNames.next_version(1, 2).should == 1

          TableNames.next_version(2, nil).should == 1
          TableNames.next_version(2, 0).should == 1
          TableNames.next_version(2, 1).should == 2
          TableNames.next_version(2, 2).should == 0
          TableNames.next_version(2, 3).should == 1
        end
      end


    end
  end
end
