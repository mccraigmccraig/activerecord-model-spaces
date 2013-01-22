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

        end
      end
    end
  end
end
