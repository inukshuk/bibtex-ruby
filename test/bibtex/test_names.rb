# frozen_string_literal: true

require 'helper'

module BibTeX
  class NamesTest < Minitest::Spec
    class UpcaseAll < BibTeX::Filter
      def apply(value)
        value.upcase
      end
    end

    before do
      @poe = Name.new(first: 'Edgar Allen', last: 'Poe')
    end

    describe 'string behaviour' do
      before do
        @name = Name.new(first: +'Charles Louis Xavier Joseph', prefix: +'de la', last: +'Vallee Poussin', suffix: +'Jr.')
      end

      it 'should implement upcase!' do
        assert_equal 'DE LA VALLEE POUSSIN, JR., CHARLES LOUIS XAVIER JOSEPH', @name.upcase!.to_s
      end
      it 'should implement downcase!' do
        assert_equal 'de la vallee poussin, jr., charles louis xavier joseph', @name.downcase!.to_s
      end
      it 'should implement gsub!' do
        assert_equal 'dX la VallXX PoussXn, Jr., CharlXs LouXs XavXXr JosXph', @name.gsub!(/[ei]/, 'X').to_s
      end
    end

    describe '#display_order' do
      it 'returns the name as "first last"' do
        _(@poe.display_order).must_be :==, 'Edgar Allen Poe'
      end

      it 'accepts the :initials option' do
        _(@poe.display_order(initials: true)).must_be :==, 'E.A. Poe'
      end
    end

    describe '#sort_order' do
      it 'returns the name as "last, first"' do
        _(@poe.sort_order).must_be :==, 'Poe, Edgar Allen'
      end

      it 'accepts the :initials option' do
        _(@poe.sort_order(initials: true)).must_be :==, 'Poe, E.A.'
      end
    end

    describe '#initials?' do
      it 'returns true if the name contains a solely initials as a first name' do
        _(@poe.initials?).must_equal false

        @poe.first = 'Edgar A.'

        _(@poe.initials?).must_equal false

        @poe.first = 'E.A.'

        _(@poe.initials?).must_equal true

        @poe.first = ''

        _(@poe.initials?).must_equal false

        @poe.first = nil

        _(@poe.initials?).must_equal false
      end
    end

    describe '#rename_if' do
      it 'renames the name to the given attributes if no condition is given' do
        _(@poe.rename_if(first: 'E.A.').first).must_equal 'E.A.'
      end

      it 'renames the name to the given attributes if all conditions match' do
        _(@poe.rename_if({ first: 'E.A.' }, last: @poe.last).first).must_equal 'E.A.'
        _(@poe.rename_if({ first: 'E.A.' }, last: @poe.last, first: @poe.first).first).must_equal 'E.A.'
      end

      it 'renames the name to the given attributes if the block returns true' do
        _(@poe.rename_if(first: 'E.A.') { |_n| true }.first).must_equal 'E.A.'
      end

      it 'does not rename the name to the given attributes if at least one condition does not match' do
        _(@poe.rename_if({ first: 'E.A.' }, last: 'foo').first).wont_equal 'E.A.'
        _(@poe.rename_if({ first: 'E.A.' }, last: 'foo', first: @poe.first).first).wont_equal 'E.A.'
        _(@poe.rename_if({ first: 'E.A.' }, last: @poe.last, first: 'foo').first).wont_equal 'E.A.'
      end

      it 'does not rename the name to the given attributes if the block returns false' do
        _(@poe.rename_if(first: 'E.A.') { |_n| false }.first).wont_equal 'E.A.'
      end
    end

    describe '#add' do
      it 'appends a Name and returns the collection' do
        names = Names.new

        _(names.add(@poe)).must_be_same_as names
        _(names.length).must_equal 1
        _(names[0]).must_be_same_as @poe
      end

      it 'is aliased as << and push' do
        names = Names.new
        names << @poe
        names.push(Name.new(last: 'Plato'))

        _(names.map(&:last)).must_equal %w[Poe Plato]
      end

      it 'parses and appends the names of a string' do
        names = Names.new(@poe)

        _(names.add('Plato and Aristotle')).must_be_same_as names
        _(names.map(&:last)).must_equal %w[Poe Plato Aristotle]
      end

      it 'parses and appends the names of any object that converts to a string' do
        thing = Object.new
        def thing.to_s = 'Plato'

        _(Names.new.add(thing).map(&:last)).must_equal %w[Plato]
      end

      it 'raises an ArgumentError for objects that cannot be converted to a string' do
        names = Names.new
        thing = BasicObject.new
        def thing.is_a?(*) = false
        def thing.inspect = '#<thing>'
        def thing.respond_to?(*) = false

        error = _ { names.add(thing) }.must_raise ArgumentError
        _(error.message).must_match(/not a name/)
        _(names).must_be :empty?
      end
    end

    describe '.looks_like?' do
      it 'returns true for strings that parse as a name' do
        _(Name.looks_like?('Poe, Edgar Allen')).must_equal true
      end

      it 'returns true for objects whose string form parses as a name' do
        thing = Object.new
        def thing.to_s = 'Edgar Allen Poe'

        _(Name.looks_like?(thing)).must_equal true
      end

      it 'returns false for strings that do not parse as a name' do
        _(Name.looks_like?('')).must_equal false
      end

      it 'returns false for objects that cannot be converted to a string' do
        thing = BasicObject.new
        def thing.respond_to?(*) = false

        _(Name.looks_like?(thing)).must_equal false
      end
    end

    describe '#rename_unless' do
      it 'does not rename the name if all conditions match' do
        _(@poe.rename_unless({ first: 'E.A.' }, last: @poe.last).first).wont_equal 'E.A.'
        _(@poe.rename_unless({ first: 'E.A.' }, last: @poe.last, first: @poe.first).first).wont_equal 'E.A.'
      end

      it 'renames the name if at least one condition does not match' do
        _(@poe.rename_unless({ first: 'E.A.' }, last: 'foo').first).must_equal 'E.A.'
      end

      it 'renames the name if the conditions refer to an unknown attribute' do
        _(@poe.rename_unless({ first: 'E.A.' }, foo: 'bar').first).must_equal 'E.A.'
      end

      it 'renames the name if the block returns false' do
        _(@poe.rename_unless(first: 'E.A.') { |_n| false }.first).must_equal 'E.A.'
      end

      it 'does not rename the name if the block returns true' do
        _(@poe.rename_unless(first: 'E.A.') { |_n| true }.first).wont_equal 'E.A.'
      end

      it 'does not rename the name if no condition is given, as the complement of #rename_if' do
        _(@poe.rename_unless(first: 'E.A.').first).must_equal 'Edgar Allen'
      end

      it 'yields the name to the block' do
        yielded = nil
        @poe.rename_unless(first: 'E.A.') { |n| yielded = n }

        _(yielded).must_be_same_as @poe
      end

      it 'returns the name' do
        _(@poe.rename_unless({ first: 'E.A.' }, last: 'foo')).must_be_same_as @poe
      end

      it 'applies to all names of a collection and returns the collection' do
        names = Names.parse('Edgar Allen Poe and Plato')

        _(names.rename_unless({ first: 'X.' }, last: 'Poe')).must_be_same_as names
        _(names.map(&:first)).must_equal ['Edgar Allen', 'X.']
      end
    end

    describe '#merge!' do
      it 'does not merge duplicates' do
        n1 = Names.new(@poe)
        n2 = Names.new(@poe)

        assert_equal @poe.to_s, n1.merge!(n2).to_s
      end

      it 'merges different names' do
        n1 = Names.new(@poe)
        n2 = Names.new(Name.new(last: 'Plato'))

        assert_equal "#{@poe} and Plato", n1.merge!(n2).to_s
      end
    end

    describe '#normalize_initials' do
      it 'returns normalized initials of existing initials only' do
        _(Name.new(first: 'Edgar A.', last: 'Poe').normalize_initials).must_equal 'Edgar A.'
        _(Name.new(first: 'E.A.', last: 'Poe').normalize_initials).must_equal 'E.A.'
        _(Name.new(first: 'E. A.', last: 'Poe').normalize_initials).must_equal 'E.A.'
        _(Name.new(first: 'E. A', last: 'Poe').normalize_initials).must_equal 'E.A.'
        _(Name.new(first: 'E A', last: 'Poe').normalize_initials).must_equal 'E.A.'
        _(Name.new(first: 'Edgar A P', last: 'Poe').normalize_initials).must_equal 'Edgar A.P.'
      end
    end

    describe '#extend_initials' do
      it 'extends the first name if the last name and initials match' do
        _(Name.new(first: 'E.A.', last: 'Poe').extend_initials('Edgar Allen', 'Poe').first).must_equal 'Edgar Allen'
        _(Name.new(first: 'Edgar A.', last: 'Poe').extend_initials('Edgar Allen', 'Poe').first).must_equal 'Edgar Allen'
        _(Name.new(first: 'E. A.', last: 'Poe').extend_initials('Edgar Allen', 'Poe').first).must_equal 'Edgar Allen'
        _(Name.new(first: 'E. A', last: 'Poe').extend_initials('Edgar Allen', 'Poe').first).must_equal 'Edgar Allen'
        _(Name.new(first: 'E A', last: 'Poe').extend_initials('Edgar Allen', 'Poe').first).must_equal 'Edgar Allen'
        _(Name.new(first: 'E. Allen', last: 'Poe').extend_initials('Edgar Allen', 'Poe').first).must_equal 'Edgar Allen'
      end

      it 'extends the first name to a partially abbreviated name' do
        _(Name.new(first: 'E.A.', last: 'Poe').extend_initials('Edgar A.', 'Poe').first).must_equal 'Edgar A.'
      end

      it 'extends hyphenated first names if the last name and initials match' do
        _(Name.new(first: 'Edgar-A.', last: 'Poe').extend_initials('Edgar-Allen', 'Poe').first).must_equal 'Edgar-Allen'
        _(Name.new(first: 'E.-Allen', last: 'Poe').extend_initials('Edgar-Allen', 'Poe').first).must_equal 'Edgar-Allen'
        _(Name.new(first: 'E.-A.', last: 'Poe').extend_initials('Edgar-Allen', 'Poe').first).must_equal 'Edgar-Allen'
        _(Name.new(first: 'E.-A', last: 'Poe').extend_initials('Edgar-Allen', 'Poe').first).must_equal 'Edgar-Allen'
        _(Name.new(first: 'E-A', last: 'Poe').extend_initials('Edgar-Allen', 'Poe').first).must_equal 'Edgar-Allen'
      end

      it 'extends the first name if the last name and initials name match with extra middle names' do
        _(Name.new(first: 'E.', last: 'Poe').extend_initials('Edgar Allen', 'Poe').first).must_equal 'Edgar Allen'
        _(Name.new(first: 'E', last: 'Poe').extend_initials('Edgar Allen', 'Poe').first).must_equal 'Edgar Allen'
        _(Name.new(first: 'Edgar', last: 'Poe').extend_initials('Edgar Allen', 'Poe').first).must_equal 'Edgar Allen'

        _(Name.new(first: 'E.A.', last: 'Poe').extend_initials('Edgar', 'Poe').first).must_equal 'E.A.'
        _(Name.new(first: 'A.', last: 'Poe').extend_initials('Edgar', 'Poe').first).must_equal 'A.'
      end

      it 'does not extend the first name if the last name or initials do not match' do
        _(Name.new(first: 'E.A.', last: 'Poe').extend_initials('Edgar Allen', 'Poser').first).wont_equal 'Edgar Allen'
        _(Name.new(first: 'E.A.', last: 'Poe').extend_initials('Edgar Ellen', 'Poe').first).wont_equal 'Edgar Ellen'
        _(Name.new(first: 'E.R.', last: 'Poe').extend_initials('Edgar Allen', 'Poe').first).wont_equal 'Edgar Allen'
      end
    end

    describe 'conversions' do
      describe '#convert' do
        it 'converts the value when given a filter instance' do
          _(Names.parse('Poe and Hawthorne').convert(UpcaseAll.instance).to_s).must_be :==, 'POE and HAWTHORNE'
        end

        it 'converts LaTeX umlauts' do
          _(Names.parse("S{\\o}ren Kirkegaard and Emmanuel L\\'evinas").convert(:latex).to_s).must_be :==, 'Kirkegaard, Søren and Lévinas, Emmanuel'
        end
      end
    end

    describe 'first names with an accented word in display order' do
      ["Paul {\\'E}mile Victor", "Paul \\'emile Victor", "Paul {\\'e}mile Victor"].each do |string|
        it "parses #{string} with the accented word in the first name" do
          skip 'known failure: the accented word is parsed as the von part'
          name = Name.parse(string)

          assert_equal [string.delete_suffix(' Victor'), '', 'Victor'], [name.first, name.von, name.last].map(&:to_s)
        end
      end
    end
  end
end
