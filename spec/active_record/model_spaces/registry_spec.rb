require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module ActiveRecord
  module ModelSpaces
    describe Registry do

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

      describe "model spaces by model" do
        it "should register a ModelSpace for a model" do
          m = double('model')
          ms = double('model-space')

          r = Registry.new
          r.send(:register_model_space_for_model, m , ms)
          r.send(:get_model_space_for_model, m).should == ms
        end

        it "should bork if a model is registered twice" do
          ms = double('model-space')
          ms.stub(:name).and_return(:foo_space)

          ms2 = double('model-space-2')

          m = double('a-model')
          m.stub(:to_s).and_return("AModel")

          r = Registry.new
          r.send(:register_model_space_for_model, m , ms)

          expect {
            r.send(:register_model_space_for_model, m, ms2)
          }.to raise_error /AModel: already registered to model space: foo_space/
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

      describe "with_model_space_context" do

        it "should bork if a non-existent model_space_name is given" do
          expect {
            r = Registry.new
            r.with_model_space_context(:foo_space, "moar_foos") {}
          }.to raise_error /no such model space: foo_space/
        end

        it "should push a new context to the stack and create a new merged contexts hash if stack empty" do
          r = Registry.new
          m = double('foo-model')
          r.register_model(m, :foo_space)

          ms = r.send(:get_model_space, :foo_space)
          ctx = double('context')
          ctx.stub(:model_space).and_return(ms)
          ctx.should_receive(:commit)

          ms.should_receive(:create_context).with("moar_foos").and_return(ctx)

          r.with_model_space_context(:foo_space, "moar_foos") do
            r.context_stack.last.should == ctx
            r.merged_context[:foo_space].should == ctx
          end
        end

        it "should resist the attempt to register a context for a model-space which already has a context" do
          r = Registry.new
          m = double('foo-model')
          r.register_model(m, :foo_space)

          ms = r.send(:get_model_space, :foo_space)
          ctx = double('context')
          ctx.stub(:model_space).and_return(ms)
          ctx.should_receive(:commit)

          ctx2 = double('context-2')
          ctx2.stub(:model_space).and_return(ms)

          ms.should_receive(:create_context).with("moar_foos").and_return(ctx)
          ms.should_receive(:create_context).with("even_moar_foos").and_return(ctx2)

          r.with_model_space_context(:foo_space, "moar_foos") do

            expect {
              r.with_model_space_context(:foo_space, "even_moar_foos") do
              end
            }.to raise_error /foo_space: already has an active context/
          end
        end


        it "should push a new context to the stack and create a new merged contexts hash if stack not empty" do
          r = Registry.new

          fm = double('foo-model')
          r.register_model(fm, :foo_space)
          fms = r.send(:get_model_space, :foo_space)
          fctx = double('foo-context')
          fctx.stub(:model_space).and_return(fms)
          fctx.should_receive(:commit)
          fms.should_receive(:create_context).with("moar_foos").and_return(fctx)

          bm = double('bar-model')
          r.register_model(bm, :bar_space)
          bms = r.send(:get_model_space, :bar_space)
          bctx = double('bar-context')
          bctx.stub(:model_space).and_return(bms)
          bctx.should_receive(:commit)
          bms.should_receive(:create_context).with("moar_bars").and_return(bctx)

          r.with_model_space_context(:foo_space, "moar_foos") do
            r.context_stack.last.should == fctx
            r.merged_context.should == {:foo_space=>fctx}

            r.with_model_space_context(:bar_space, "moar_bars") do
              r.context_stack.last.should == bctx
              r.merged_context.should == {:foo_space=>fctx, :bar_space=>bctx}
            end

            r.context_stack.last.should == fctx
            r.merged_context.should == {:foo_space=>fctx}
          end

        end
      end

    end
  end
end
