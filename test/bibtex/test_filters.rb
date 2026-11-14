require 'helper'

module BibTeX
  class FiltersTest < Minitest::Spec
    it 'should Filters should be singleton classes' do
      refute_respond_to Filter, :new
      assert_same Filter.instance, Filter.instance
    end

    describe 'Filters.resolve' do
      it 'should return the filter if a filter is given' do
        assert_same Filter.instance, Filters.resolve(Filter.instance)
      end

      it 'should return the parameter if it quacks like a filter' do
        f = Object.new
        def f.apply
          nil
        end

        assert_same f, Filters.resolve(f)
      end

      it 'should return the filter if there is a filter by that name' do
        foo_bar = FiltersTest.const_set(:FooBar, Class.new(Filter))

        assert_same foo_bar.instance, Filters.resolve(:foobar)
        assert_same foo_bar.instance, Filters.resolve('foobar')
      ensure
        Filter.subclasses.delete(foo_bar)
        FiltersTest.send(:remove_const, :FooBar)
      end

      it 'should return nil if there is no filter by that name' do
        assert_nil Filters.resolve(:foobar)
        assert_nil Filters.resolve('foobar')
        assert_nil Filters.resolve(nil)
      end
    end
  end
end
