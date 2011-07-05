require 'helper.rb'

module BibTeX
  class ValueTest < MiniTest::Spec
    
    context "when empty" do
      should "be equal to an empty string" do
        assert Value.new == ''
        assert Value.new('') == ''
      end
      should "be empty" do
        assert Value.new.empty?
        assert Value.new('').empty?
      end
      should "match an empty pattern" do
        assert Value.new =~ //
        assert Value.new('') =~ //
      end
    end
    
    context "#join" do
      should "return empty string when empty" do
        assert_equal '', Value.new.join.to_s
        assert_equal '', Value.new('').join.to_s
      end
      should "return the string if atomic" do
        assert_equal 'foo', Value.new('foo').join.to_s
      end
      should "return a string concatenation of all strings when containing only strings" do
        assert_equal 'foobar', Value.new('foo', 'bar').join.to_s
        assert_equal 'foobar', Value.new(['foo', 'bar']).join.to_s
      end
      should "should be atomic after join when containing only strings" do
        refute Value.new('foo', 'bar').atomic?
        assert Value.new('foo', 'bar').join.atomic?
      end
      should "do nothing when containing only symbols" do
        value = Value.new(:foo)
        assert_equal value, value.join
        value = Value.new(:foo, :bar)
        assert_equal value, value.join
      end
      should "do nothing when containing only symbols and a single string" do
        value = Value.new(:foo, 'bar')
        assert_equal value, value.join
        value = Value.new('foo', :bar)
        assert_equal value, value.join
      end
    end
  
    context "#to_s" do
      should "return the string if atomic" do
        assert_equal 'foo bar', Value.new('foo bar').to_s
      end
      should "return the symbol as string when containing only a single symbol" do
        assert_equal 'foo', Value.new(:foo).to_s
      end
      should "return all string tokens concatenated by #" do
        assert_equal '"foo" # "bar"', Value.new('foo', 'bar').to_s
      end
      should "return all symbol tokens concatenated by #" do
        assert_equal 'foo # bar', Value.new(:foo, :bar).to_s
      end
      should "return all symbol and string tokens concatenated by #" do
        assert_equal 'foo # "bar"', Value.new(:foo, 'bar').to_s
        assert_equal '"foo" # bar', Value.new('foo', :bar).to_s
      end
    end
    
    context "conversions" do
      setup do
        class Upcase < BibTeX::Filter
          def apply (value)
            value.is_a?(::String) ? value.upcase : value
          end
        end
        @values = [Value.new('foo'), Value.new('foo', :bar)]
      end
      
      context "#convert" do
        should "convert the value when given a filter instance" do
          assert_equal ['FOO', '"FOO" # bar'], @values.map { |v| v.convert(Upcase.instance).to_s }
        end

        should "convert the value when given a filter class" do
          assert_equal ['FOO', '"FOO" # bar'], @values.map { |v| v.convert(Upcase).to_s }
        end

        should "convert the value when given the name of a filter" do
          assert_equal ['FOO', '"FOO" # bar'], @values.map { |v| v.convert(:upcase).to_s }
          assert_equal ['FOO', '"FOO" # bar'], @values.map { |v| v.convert('upcase').to_s }
        end

        should "convert the value when using a ghost method" do
          assert_equal ['FOO', '"FOO" # bar'], @values.map { |v| v.convert_upcase.to_s }
        end
        
        should "not alter the value when using a filter name" do
          @values.each { |v| v.convert(:upcase) }
          assert_equal ['foo', '"foo" # bar'], @values.map(&:to_s)
        end

        should "not alter the value when using a ghost method" do
          @values.each { |v| v.convert_upcase }
          assert_equal ['foo', '"foo" # bar'], @values.map(&:to_s)
        end
      end
      
      context "#convert!" do
        should "convert the value when given the name of a filter" do
          assert_equal ['FOO', '"FOO" # bar'], @values.map { |v| v.convert!(:upcase).to_s }
        end
        
        should "alter the value when given the name of a filter" do
          @values.each { |v| v.convert!(:upcase) }
          assert_equal ['FOO', '"FOO" # bar'], @values.map(&:to_s)
        end

        should "alter the value when using a ghost method" do
          @values.each { |v| v.convert_upcase! }
          assert_equal ['FOO', '"FOO" # bar'], @values.map(&:to_s)
        end
        
      end
      
      context "#to_s" do
        should 'accept a :filter option and convert the values accordingly without changing the value' do
          assert_equal '"FOO" # bar', @values[1].to_s(:filter => :upcase)
          assert_equal '"foo" # bar', @values[1].to_s
        end
      end
    end
    
  end
end