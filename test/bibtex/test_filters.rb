require 'helper.rb'

module BibTeX
  class FiltersTest < Minitest::Spec
    it 'should Filters should be singleton classes' do
      assert_equal false, Filter.respond_to?(:new)
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
        class FooBar < Filter; end

        assert_same FooBar.instance, Filters.resolve(:foobar)
        assert_same FooBar.instance, Filters.resolve('foobar')
        Filter.subclasses.delete(FooBar)
      end

      it 'should return nil if there is no filter by that name' do
        assert_nil Filters.resolve(:foobar)
        assert_nil Filters.resolve('foobar')
        assert_nil Filters.resolve(nil)
      end
    end
  end
end
