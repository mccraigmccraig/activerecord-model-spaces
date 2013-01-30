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
        it "should return base_table_name if no model-space or model-space-key given" do
          TableNames.model_space_table_name(nil, nil, "foo_bars").should == "foo_bars"
        end

        it "should return base_table_name if an empty model-space and model-space-key given" do
          TableNames.model_space_table_name("", "", "foo_bars").should == "foo_bars"
        end

        it "should prefix with model-space-name if given alone" do
          TableNames.model_space_table_name("blarghl", nil, "foo_bars").should == "blarghl__foo_bars"
        end

        it "should prefix a model-space-name and model-space-key if bothgiven" do
          TableNames.model_space_table_name("blarghl", "one", "foo_bars").should == "blarghl__one__foo_bars"
        end

        it "should raise an error if a model-space-key is given without a model-space-name" do

          expect {
            TableNames.model_space_table_name(nil, "one", "FooBar")
          }.to raise_error /model_space_key cannot be non-empty if model_space_name is empty/

        end
      end

      describe "table_name" do
        it "should always suffix version provided if non-nil and >0" do
          TableNames.table_name("blarghl", "one", "foo_bars", nil, nil).should == "blarghl__one__foo_bars"
          TableNames.table_name("blarghl", "one", "foo_bars", nil, 1).should == "blarghl__one__foo_bars__1"
          TableNames.table_name("blarghl", "one", "foo_bars", 0, nil).should == "blarghl__one__foo_bars"
          TableNames.table_name("blarghl", "one", "foo_bars", 0, 1).should == "blarghl__one__foo_bars__1"

          TableNames.table_name("blarghl", "one", "foo_bars", 1, 0).should == "blarghl__one__foo_bars"
          TableNames.table_name("blarghl", "one", "foo_bars", 1, 1).should == "blarghl__one__foo_bars__1"
          TableNames.table_name("blarghl", "one", "foo_bars", 1, 2).should == "blarghl__one__foo_bars__2"
          TableNames.table_name("blarghl", "one", "foo_bars", 1, 3).should == "blarghl__one__foo_bars__3"

          TableNames.table_name("blarghl", "one", "foo_bars", 2, 0).should == "blarghl__one__foo_bars"
          TableNames.table_name("blarghl", "one", "foo_bars", 2, 1).should == "blarghl__one__foo_bars__1"
          TableNames.table_name("blarghl", "one", "foo_bars", 2, 2).should == "blarghl__one__foo_bars__2"
          TableNames.table_name("blarghl", "one", "foo_bars", 2, 3).should == "blarghl__one__foo_bars__3"
          TableNames.table_name("blarghl", "one", "foo_bars", 2, 4).should == "blarghl__one__foo_bars__4"
        end
      end

      describe "next_version" do
        it "should return the next version" do
          TableNames.next_version(nil, nil).should == 0
          TableNames.next_version(nil, 0).should == 0
          TableNames.next_version(nil, 1).should == 0

          TableNames.next_version(0, nil).should == 0
          TableNames.next_version(0, 0).should == 0
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
