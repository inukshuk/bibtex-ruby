# frozen_string_literal: true

require 'helper'

module BibTeX
  # Dynamic field writers on BibTeX::Entry.
  class EntryWritersTest < Minitest::Spec
    describe 'dynamic field writers' do
      before do
        @entry = Entry.new(bibtex_type: :book, bibtex_key: :moby, title: 'Moby Dick', keywords: 'whale')
      end

      describe 'entry.foo = value' do
        it 'adds a new field' do
          @entry.isbn = '978-0142437247'

          assert_includes @entry.fields.keys, :isbn
          assert_equal '978-0142437247', @entry[:isbn].to_s
        end

        it 'adds a field with a name that has no reader yet' do
          @entry.foo = 'bar'

          assert_equal 'bar', @entry.foo.to_s
        end

        it 'replaces the value of an existing field' do
          @entry.keywords = 'sea'

          assert_equal 'sea', @entry.keywords.to_s
          assert_equal %i[title keywords], @entry.fields.keys
        end

        it 'stores the value as a BibTeX::Value, like #add' do
          @entry.edition = 1851

          assert_kind_of Value, @entry[:edition]
          assert_equal '1851', @entry[:edition].to_s
        end

        it 'converts values exactly as #add does' do
          ['Herman Melville', 1851, Value.new('x'), Names.new(Name.new(first: 'Herman', last: 'Melville'))].each do |value|
            via_add = Entry.new(bibtex_type: :misc).add(:abstract, value)
            via_writer = Entry.new(bibtex_type: :misc)
            via_writer.abstract = value

            assert_equal via_add[:abstract].class, via_writer[:abstract].class, "class for #{value.inspect}"
            assert_equal via_add[:abstract].to_s, via_writer[:abstract].to_s, "value for #{value.inspect}"
          end
        end

        it 'preserves BibTeX::Names (and other subclasses of BibTeX::Value)' do
          @entry.narrator = Names.new(Name.new(first: 'Herman', last: 'Melville'))

          assert_instance_of Names, @entry[:narrator]
        end

        it 'does not share the assigned Value object, like #add' do
          value = Value.new('shared')
          @entry.abstract = value

          refute_same value, @entry[:abstract]
        end

        it 'works through send and public_send with Symbol and String names' do
          @entry.send(:abstract=, 'a')

          assert_equal 'a', @entry.abstract.to_s

          writer = 'abstract='
          @entry.public_send(writer, 'b')

          assert_equal 'b', @entry.abstract.to_s
        end

        it 'works for entries built with a block' do
          entry = Entry.new do |e|
            e.type = :book
            e.key = :key
            e.address = 'New York'
          end

          assert_equal 'New York', entry.address.to_s
        end

        it 'makes the new field part of the BibTeX output' do
          @entry.isbn = '978-0142437247'

          assert_match(/isbn = \{978-0142437247\}/, @entry.to_s)
        end

        it 'sets the field on a cross-referencing entry without touching the parent' do
          bib = Bibliography.parse('@book{a, abstract = "A"} @incollection{a1, crossref = "a"}')

          assert_equal 'A', bib['a1'].abstract.to_s

          bib['a1'].abstract = 'Child'

          assert_equal 'Child', bib['a1'].abstract.to_s
          assert_equal 'A', bib['a'].abstract.to_s
          assert bib['a1'].field?(:abstract)
        end
      end

      describe '#respond_to? for writers' do
        it 'returns exactly true for a Symbol writer name' do
          assert_same true, @entry.respond_to?(:foo=)
        end

        it 'returns exactly true for a String writer name' do
          writer = 'foo='

          assert_same true, @entry.respond_to?(writer)
        end

        it 'returns exactly true for the writer of an existing field' do
          writer = 'keywords='

          assert_same true, @entry.respond_to?(:keywords=)
          assert_same true, @entry.respond_to?(writer)
        end

        it 'returns exactly true on an empty entry' do
          assert_same true, Entry.new.respond_to?(:anything=)
        end

        it 'exposes the writer through #method' do
          @entry.method(:abstract=).call('via method')

          assert_equal 'via method', @entry.abstract.to_s
        end
      end

      describe 'a method name made only of "="' do
        it 'is not a writer according to respond_to? (Symbol)' do
          refute_respond_to @entry, :'='
        end

        it 'is not a writer according to respond_to? (String)' do
          name = '='

          refute_respond_to @entry, name
        end

        it 'raises NoMethodError when called' do
          assert_raises(NoMethodError) { @entry.send(:'=', 'x') }
          name = '='

          assert_raises(NoMethodError) { @entry.public_send(name, 'x') }
        end

        it 'does not add a field' do
          assert_raises(NoMethodError) { @entry.send(:'=', 'x') }

          assert_equal %i[title keywords], @entry.fields.keys
        end
      end

      describe "a writer name whose field part ends in '=' (a==)" do
        it 'is not a writer' do
          refute_respond_to @entry, :'a=='
          assert_raises(NoMethodError) { @entry.send(:'a==', 'x') }
          assert_equal %i[title keywords], @entry.fields.keys
        end
      end

      describe 'unknown methods' do
        it 'still raise NoMethodError for undefined readers' do
          assert_raises(NoMethodError) { @entry.undefined_field }
        end

        it 'still report undefined readers as not responding' do
          refute_respond_to @entry, :undefined_field
        end
      end

      describe 'existing dynamic behaviour' do
        it 'keeps field readers' do
          assert_equal 'Moby Dick', @entry.title.to_s
          assert_respond_to @entry, :title
        end

        it 'keeps convert_<filter> and convert_<filter>!' do
          entry = Entry.new(bibtex_type: :book, title: 'M\"{o}by')

          assert_equal 'Möby', entry.convert_latex.title.to_s
          assert_equal 'M\"{o}by', entry.title.to_s

          entry.convert_latex!

          assert_equal 'Möby', entry.title.to_s
        end

        it 'keeps from_<filter>' do
          entry = Entry.new(bibtex_type: :book, title: 'M\"{o}by')

          assert_equal 'Möby', entry.from_latex.title.to_s
        end

        it 'reports the ghost conversion methods via respond_to?' do
          assert_respond_to @entry, :convert_latex
          assert_respond_to @entry, :convert_latex!
          assert_respond_to @entry, :from_latex
        end

        it 'keeps delegating readers to a cross-referenced parent' do
          bib = Bibliography.parse('@book{a, title = "A", editor = "E"} @incollection{a1, crossref = "a"}')

          assert_equal 'A', bib['a1'].title.to_s
          assert_respond_to bib['a1'], :title
          assert_respond_to bib['a1'], :editor
          refute bib['a1'].field?(:title)
        end
      end

      describe 'real methods and operators' do
        it 'keeps key= as the key writer, not a field' do
          @entry.key = 'melville'

          assert_equal 'melville', @entry.key
          refute @entry.field?(:key)
        end

        it 'keeps type= as the type writer, not a field' do
          @entry.type = :article

          assert_equal :article, @entry.type
          refute @entry.field?(:type)
        end

        it 'keeps []= as before' do
          @entry[:isbn] = '978-0142437247'

          assert_equal '978-0142437247', @entry[:isbn].to_s
        end

        it 'keeps the generated writers of required and name fields' do
          @entry.title = 'Billy Budd'
          @entry.author = 'Herman Melville'

          assert_equal 'Billy Budd', @entry.title.to_s
          assert_equal 'Herman Melville', @entry.author.to_s
        end

        it 'keeps == as before' do
          other = Entry.new(bibtex_type: :book, bibtex_key: :moby, title: 'Moby Dick', keywords: 'whale')

          assert_equal other, @entry
          refute_equal Entry.new(bibtex_type: :book, bibtex_key: :moby, title: 'Typee'), @entry
          refute @entry.field?(:'=')
        end

        it 'keeps <=> and <= as before' do
          a = Entry.new(bibtex_type: :article, bibtex_key: :a)
          b = Entry.new(bibtex_type: :book, bibtex_key: :b)

          assert_equal(-1, a <=> b)
          assert_operator a, :<=, b
          assert_operator b, :>, a
          assert_empty a.fields
        end
      end
    end
  end
end
