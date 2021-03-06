require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module ActiveRecord
  module ModelSpaces
    describe Registry do

      describe "context_stack" do
        it "should retrieve the context-stack from a Thread local" do
          cs = double('context-stack')
          Thread.current.should_receive("[]").with(Registry::CONTEXT_STACK_KEY).and_return(cs)

          r = Registry.new
          r.send(:context_stack).should == cs
        end

        it "should initialise the context-stack if necessary" do
          Thread.current.should_receive('[]=').with(Registry::CONTEXT_STACK_KEY, []).and_return([])
          r = Registry.new
          r.send(:context_stack).should == []
        end
      end

      describe "merged_context" do
        it "should retrieve the merged-context from a Thread local" do
          mc = double('merged-context')
          Thread.current.should_receive("[]").with(Registry::MERGED_CONTEXT_KEY).and_return(mc)

          r = Registry.new
          r.send(:merged_context).should == mc
        end
      end

      def create_model(name, superklass=ActiveRecord::Base)
        m = Class.new(superklass)
        m.stub(:to_s).and_return(name)
        m.stub(:inspect).and_return(name)
        m
      end

      describe "reset!" do
        it "should reset model and model_space registrations" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)
          r.send(:get_model_space, :foo_space).is_registered?(m).should == true
          r.reset!
          r.send(:get_model_space, :foo_space).should == nil
          r.send(:unchecked_get_model_space_for_model, m).should == nil
        end
      end

      describe "register_model" do
        it "should register a model" do
          r = Registry.new
          m = create_model('FooModeln')
          r.register_model(m, :foo_space)
          r.send(:get_model_space, :foo_space).is_registered?(m).should == true
        end
      end

      describe "base_table_name" do
        it "should retrieve the models base_table_name" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)
          r.base_table_name(m).should == "foo_models"

          m2 = create_model('BarModel')
          r.register_model(m2, :foo_space, :base_table_name=>"moar_models")
          r.base_table_name(m2).should == "moar_models"
        end
      end

      describe "set_base_table_name" do
        it "should set a base_table_name" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)
          r.base_table_name(m).should == "foo_models"
          r.set_base_table_name(m, "random_models")
          r.base_table_name(m).should == "random_models"
        end

        it "should provide an informative error if the model is not yet registered to a model space" do
          r = Registry.new
          m = create_model('FooModel')

          expect {
            r.set_base_table_name(m, "random_models")
          }.to raise_error /FooModel is not \(yet\) registered to a ModelSpace/
        end
      end

      describe "table_name" do
        it "should call base_table_name on the model's ModelSpace if no context is registered and !enforce_context" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          ms = r.send(:get_model_space, :foo_space)
          ms.should_receive(:base_table_name).with(m)

          r.table_name(m)
        end

        it "should bork if no context is registered for the model's ModelSpace and enforce_context" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          r.set_enforce_context(true)

          expect {
            r.table_name(m)
          }.to raise_error /'foo_space' has no current context/
        end
      end

      describe "get_active_key" do
        it "should return the key if a context is registered" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          ms = r.send(:get_model_space, :foo_space)
          ctx = double('foo-context')
          ctx.stub(:model_space).and_return(ms)
          msk = double('foo-space-key')
          ctx.stub(:model_space_key).and_return(msk)
          ctx.should_receive(:commit)
          ms.should_receive(:create_context).with(:one).and_return(ctx)
          r.with_context(:foo_space, :one) { r.active_key(:foo_space) }.should == msk
        end

        it "should return nil if no context is registered" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          r.active_key(:foo_space).should == nil
        end

        it "should bork if the model_space is not registered" do
          r = Registry.new
          expect {
            r.active_key(:foo_space)
          }.to raise_error /no such model space: foo_space/

        end
      end

      describe "context proxy methods" do
        it "should call table_name on the live context" do

          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          ms = r.send(:get_model_space, :foo_space)
          ctx = double('foo-one-context')
          ctx.stub(:model_space).and_return(ms)
          ctx.should_receive(:commit)
          ms.should_receive(:create_context).with(:one).and_return(ctx)
          ctx.should_receive(:table_name).with(m)
          r.with_context(:foo_space, :one) {r.table_name(m)}

          ctx2 = double('foo-two-context')
          ctx2.stub(:model_space).and_return(ms)
          ctx2.should_receive(:commit)
          ms.should_receive(:create_context).with(:two).and_return(ctx2)
          ctx2.should_receive(:current_table_name).with(m)
          r.with_context(:foo_space, :two) {r.current_table_name(m)}

          ctx3 = double('foo-three-context')
          ctx3.stub(:model_space).and_return(ms)
          ctx3.should_receive(:commit)
          ms.should_receive(:create_context).with(:three).and_return(ctx3)
          ctx3.should_receive(:working_table_name).with(m)
          r.with_context(:foo_space, :three) {r.working_table_name(m)}

          ctx4 = double('foo-four-context')
          ctx4.stub(:model_space).and_return(ms)
          ctx4.should_receive(:commit)
          ms.should_receive(:create_context).with(:four).and_return(ctx4)
          ctx4.should_receive(:hoover)
          r.with_context(:foo_space, :four) {r.hoover(m)}

          ctx5 = double('foo-five-context')
          ctx5.stub(:model_space).and_return(ms)
          ctx5.should_receive(:commit)
          ms.should_receive(:create_context).with(:five).and_return(ctx5)
          ctx5.should_receive(:new_version).and_return{|model,&block|
            model.should == m
            block.call
          }
          r.with_context(:foo_space, :five) {
            r.new_version(m){ :result }.should == :result
          }

          ctx6 = double('foo-six-context')
          ctx6.stub(:model_space).and_return(ms)
          ctx6.should_receive(:commit)
          ms.should_receive(:create_context).with(:six).and_return(ctx6)
          ctx6.should_receive(:updated_version).and_return{|model, &block|
            model.should == m
            block.call
          }
          r.with_context(:foo_space, :six) {
            r.updated_version(m){ :result }.should == :result
          }
        end
      end

      describe "with_context" do

        it "should bork if a non-existent model_space_name is given" do
          expect {
            r = Registry.new
            r.with_context(:foo_space, "moar_foos") {}
          }.to raise_error /no such model space: foo_space/
        end

        it "should push a new context to the stack and create a new merged contexts hash if stack empty" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          ms = r.send(:get_model_space, :foo_space)
          ctx = double('context')
          ctx.stub(:model_space).and_return(ms)
          ctx.should_receive(:commit)

          ms.should_receive(:create_context).with("moar_foos").and_return(ctx)

          r.with_context(:foo_space, "moar_foos") do
            r.send(:context_stack).last.should == ctx
            r.send(:merged_context)[:foo_space].should == ctx
            :result
          end.should == :result
        end

        it "should resist the attempt to register a context for a model-space which already has a context" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          ms = r.send(:get_model_space, :foo_space)
          ctx = double('context')
          ctx.stub(:model_space).and_return(ms)
          ctx.stub(:model_space_key).and_return(:moar_foos)
          ctx.should_receive(:commit)

          ms.should_receive(:create_context).with("moar_foos").and_return(ctx)

          r.with_context(:foo_space, "moar_foos") do

            expect {
              r.with_context(:foo_space, "even_moar_foos") do
              end
            }.to raise_error /ModelSpace: foo_space: context with key moar_foos already active/
          end
        end

        it "should just call the block if a context is registered for a model-space which already has a context with the same model-space-key" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          ms = r.send(:get_model_space, :foo_space)
          ctx = double('context')
          ctx.stub(:model_space).and_return(ms)
          ctx.stub(:model_space_key).and_return(:moar_foos)
          ctx.should_receive(:commit)

          ms.should_receive(:create_context).with(:moar_foos).and_return(ctx)

          r.with_context(:foo_space, :moar_foos) do

            r.with_context(:foo_space, "moar_foos") do
              :one_million_pounds
            end

          end.should == :one_million_pounds
        end

        it "should push a new context to the stack and create a new merged contexts hash if stack not empty" do
          r = Registry.new

          fm = create_model('FooModel')
          r.register_model(fm, :foo_space)
          fms = r.send(:get_model_space, :foo_space)
          fctx = double('foo-context')
          fctx.stub(:model_space).and_return(fms)
          fctx.should_receive(:commit)
          fms.should_receive(:create_context).with("moar_foos").and_return(fctx)

          bm = create_model('BarModel')
          r.register_model(bm, :bar_space)
          bms = r.send(:get_model_space, :bar_space)
          bctx = double('bar-context')
          bctx.stub(:model_space).and_return(bms)
          bctx.should_receive(:commit)
          bms.should_receive(:create_context).with("moar_bars").and_return(bctx)

          r.with_context(:foo_space, "moar_foos") do
            r.send(:context_stack).last.should == fctx
            r.send(:merged_context).should == {:foo_space=>fctx}

            r.with_context(:bar_space, "moar_bars") do
              r.send(:context_stack).last.should == bctx
              r.send(:merged_context).should == {:foo_space=>fctx, :bar_space=>bctx}
              :inner_result
            end.should == :inner_result

            r.send(:context_stack).last.should == fctx
            r.send(:merged_context).should == {:foo_space=>fctx}
            :outer_result
          end.should == :outer_result

        end
      end

      describe "kill_context" do
        it "should call kill_context on the named model_space" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          ms = r.send(:get_model_space, :foo_space)
          ms.should_receive(:kill_context).with(:one)

          r.kill_context(:foo_space, :one)
        end
      end


      describe "model spaces registry" do
        it "should create a ModelSpace object if it doesn't exist" do
          r = Registry.new
          r.send(:register_model_space, :foo)
          r.send(:get_model_space, :foo).should_not == nil
        end

        it "should register with a keyword name if a string is given" do
          r = Registry.new
          r.send(:register_model_space, "foo")
          ms = r.send(:get_model_space, :foo)
          ms.should_not == nil
          ms.name.should == :foo
          r.send(:get_model_space, "foo").should == ms
        end
      end

      describe "unchecked_get_model_space_for_model" do
        it "should retrieve a model space for a model" do
          m = create_model('FooModel')
          r = Registry.new
          r.register_model(m, :foo_space)
          r.send(:unchecked_get_model_space_for_model, m).should == r.send(:get_model_space, :foo_space)
        end

        it "should return nil if the model is not registered to a model space" do
          m = create_model('FooModel')
          r = Registry.new
          r.send(:unchecked_get_model_space_for_model, m).should == nil
        end

        it "should check the superclass chain for registrations and return the model space for the nearest registered superclass" do
          m1 = create_model('FooModel')
          m2 = create_model('BarModel', m1)

          r = Registry.new
          r.register_model(m1, :foo_space)
          r.send(:unchecked_get_model_space_for_model, m2).should == r.send(:get_model_space, :foo_space)
        end
      end


      describe "model spaces by model" do
        it "should register a ModelSpace for a model" do
          m = create_model('FooModel')
          ms = double('model-space')

          r = Registry.new
          r.send(:register_model_space_for_model, m , ms)
          r.send(:unchecked_get_model_space_for_model, m).should == ms
          r.send(:get_model_space_for_model, m).should == ms
        end

        it "should bork if a model is not registered" do
          m = create_model('A::SomeModel')

          r = Registry.new
          expect {
            r.send(:get_model_space_for_model, m)
          }.to raise_error /A::SomeModel is not registered to any ModelSpace/
        end

        it "should re-register if a model is registered twice" do
          m = create_model('AModel')

          r = Registry.new
          r.register_model(m, :foo_space, :history_versions=>2)

          fs = r.send(:get_model_space, :foo_space)
          r.send(:get_model_space_for_model, m).should == fs
          fs.is_registered?(m).should == true
          fs.history_versions(m).should == 2

          r.register_model(m, :bar_space, :base_table_name=>"moar_models")

          fs.is_registered?(m).should == false

          bs = r.send(:get_model_space, :bar_space)
          r.send(:get_model_space_for_model, m).should == bs
          bs.is_registered?(m).should == true
          bs.history_versions(m).should == 0
          bs.base_table_name(m).should == "moar_models"
        end
      end

      describe "merge_context_stack" do

        it "should merge contexts into a hash of contexts" do
          ms1 = double('model-space-1')
          ms1.stub(:name).and_return(:space_1)
          ctx1 = double('context-1')
          ctx1.stub(:model_space).and_return(ms1)

          ms2 = double('model-space-2')
          ms2.stub(:name).and_return(:space_2)
          ctx2 = double('context-2')
          ctx2.stub(:model_space).and_return(ms2)

          r = Registry.new
          r.stub(:context_stack).and_return( [ctx1, ctx2] )

          r.send(:merge_context_stack).should == {:space_1=>ctx1, :space_2=>ctx2}
        end
      end

      describe "unchecked_get_context_for_model" do
        it "should return an active context" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          ms = r.send(:get_model_space, :foo_space)
          ctx = double('context')
          ctx.stub(:model_space).and_return(ms)
          ctx.should_receive(:commit)

          ms.should_receive(:create_context).with("moar_foos").and_return(ctx)

          r.with_context(:foo_space, "moar_foos") do
            r.send(:unchecked_get_context_for_model, m).should == ctx
          end
        end

        it "should return nil if the model_space of the model is unknown" do
          r = Registry.new
          m = create_model('FooModel')
          r.send(:unchecked_get_context_for_model, m).should == nil
        end

        it "should return nil if the model_space is known but there is no active context" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          ms = r.send(:get_model_space, :foo_space)

          r.send(:unchecked_get_context_for_model, m).should == nil
        end
      end

      describe "get_context_for_model" do

        it "should bork if the model is not registered to a model space" do
          r = Registry.new

          m = create_model('A::Foo')

          expect {
            r.send(:get_context_for_model, m)
          }.to raise_error /A::Foo is not registered to any ModelSpace/
        end

        it "should bork if the model's ModelSpace has no current context" do
          r = Registry.new

          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          expect {
            r.send(:get_context_for_model, m)
          }.to raise_error /ModelSpace: 'foo_space' has no current context/
        end

        it "should return the registered context for the model's ModelSpace" do
          r = Registry.new
          m = create_model('FooModel')
          r.register_model(m, :foo_space)

          ms = r.send(:get_model_space, :foo_space)
          ctx = double('context')
          ctx.stub(:model_space).and_return(ms)
          ctx.should_receive(:commit)

          ms.should_receive(:create_context).with("moar_foos").and_return(ctx)

          r.with_context(:foo_space, "moar_foos") do
            r.send(:get_context_for_model, m).should == ctx
          end

        end
      end


    end
  end
end
