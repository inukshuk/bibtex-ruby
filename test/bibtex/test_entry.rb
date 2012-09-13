# -*- coding: utf-8 -*-

require 'helper.rb'

module BibTeX
  class EntryTest < MiniTest::Spec

    describe 'a new entry' do
      it "won't be nil" do
        Entry.new.wont_be_nil
      end
    end

    describe '#add' do
      it 'preserves BibTeX::Names (and other subclasses of BibTeX::Value)' do
        e = Entry.new
        e.add(:author, Names.new(Name.new(:first => 'first_name')))
        assert_equal e[:author].class, Names
      end
    end

    describe 'cross-references' do
      it 'has no cross-reference by default' do
        assert_equal false, Entry.new.has_cross_reference?
      end
      
      it 'is not cross-referenced by default' do
        assert_equal false, Entry.new.cross_referenced?
        Entry.new.cross_referenced_by.must_be_empty
      end
      
      describe 'given a bibliography with cross referenced entries' do
        before do
          @bib = Bibliography.parse <<-END
            @book{a, editor = "A", title = "A"}
            @incollection{a1, crossref = "a"}
            @incollection{b1, crossref = "b"}
          END
        end
        
        describe '#has_cross_reference?' do
          it 'returns true if the entry has a valid cross-reference' do
            assert_equal true, @bib['a1'].has_cross_reference?
          end
          it 'returns false if the entry has no valid cross-reference' do
            assert_equal false, @bib['a'].has_cross_reference?
            assert_equal false, @bib['b1'].has_cross_reference?
          end
        end
        
        describe '#cross_referenced?' do
          it 'returns true if the entry is cross-referenced by another entry' do
            assert_equal true, @bib['a'].cross_referenced?
          end
          it 'returns false if the entry is not cross-referenced' do
            assert_equal false, @bib['a1'].cross_referenced?
          end
        end
        
        describe '#cross_referenced_by' do
          it 'returns a list of all entries that cross-reference this entry' do
            @bib['a'].cross_referenced_by.must_include(@bib['a1'])
          end
          
          it 'returns an empty list if there are no cross-references to this entry' do
            @bib['a1'].cross_referenced_by.must_be_empty
          end
        end
        
        describe '#respond_to?' do
          it 'takes into account the inherited attributes' do
            @bib['a1'].respond_to?(:title)
          end
        end
        
        describe 'resolve field values using array accessors #[]' do
          describe 'when a "title" is set in the entry itself' do
            before { @bib['a1'].title = 'A1' }
            it 'returns the title' do
              @bib['a1'].title.must_be :==, 'A1'
            end
          end
          
          describe 'when "title" is undefined for the entry but defined in the reference' do
            it 'returns the referenced title' do
              @bib['a1'].title.must_be :==, @bib['a'].title
            end
          end
          
          describe 'when "booktitle" is undefined for the entry but defined in the reference' do
            before { @bib['a'].booktitle = "A Booktitle" }
            it 'returns the referenced booktitle' do
              @bib['a1'].booktitle.must_be :==, @bib['a'].booktitle
            end
          end

          describe 'when "booktitle" is undefined for the entry and the reference but the reference has a "title"' do
            it "returns the reference's title" do
              @bib['a1'].booktitle.must_be :==, @bib['a'].title
            end
          end
          
          it 'does not store referenced values permanently' do
            refute_nil @bib['a1'].booktitle
            assert_nil @bib['a1'].fields[:booktitle]
          end

          describe '#inherited_fields' do
            it 'returns an empty list by default' do
              Entry.new.inherited_fields.must_be_empty
            end
            
            it 'returns an empty list if this entry has no cross-reference' do
              @bib['a'].inherited_fields.must_be_empty
            end
            
            it 'returns an empty list if this entry has a cross-reference but the reference does not exist in the bibliography' do
              @bib['b1'].inherited_fields.must_be_empty
            end
            
            it 'returns a list of all fields not set in the field but in the reference' do
              @bib['a1'].inherited_fields.must_be :==, [:booktitle, :editor, :title]
            end
          end
          
          describe '#save_inherited_fields' do
            it 'copies referenced values to the entry' do
              @bib['a1'].title = 'a1'
              @bib['a1'].save_inherited_fields
              @bib['a1'].fields[:booktitle].must_be :==, @bib['a'].title
              @bib['a1'].fields[:title].wont_be :==, @bib['a'].title
            end
          end
        end
        
      end
    end
    
    describe '#names' do
      it 'returns an empty list by default' do
        Entry.new.names.must_be :==, []
      end
      
      it 'returns the author (if set)' do
        Entry.new(:author => 'A').names.must_be :==, %w{ A }
      end

      it 'returns all authors (if set)' do
        Entry.new(:author => 'A B and C D').parse_names.names.length.must_be :==, 2
      end
      
      it 'returns the editor (if set)' do
        Entry.new(:editor => 'A').names.must_be :==, %w{ A }
      end

      it 'returns the translator (if set)' do
        Entry.new(:translator => 'A').names.must_be :==, %w{ A }
      end
      
    end
    
    describe 'month conversion' do
      before do
        @entry = Entry.new
      end
      
      [[:jan,'January'], [:feb,'February'], [:sep,'September']].each do |m|
        it 'should convert english months' do
          @entry.month = m[1]
          assert_equal m[0], @entry.month.v
        end
      end

      [[:jan,:jan], [:feb,:feb], [:sep,:sep]].each do |m|
        it 'should convert bibtex abbreviations' do
          @entry.month = m[1]
          assert_equal m[0], @entry.month.v
        end
      end

      [[:jan,1], [:feb,2], [:sep,9]].each do |m|
        it 'should convert numbers' do
          @entry.month = m[1]
          assert_equal m[0], @entry.month.v
        end
        it 'should convert numbers when parsing' do
          @entry = Entry.parse("@misc{id, month = #{m[1]}}")[0]
          assert_equal m[0], @entry.month.v
        end
      end
      
    end

    describe 'given an entry' do
      before do
        @entry = Entry.new do |e|
          e.type = :book
          e.key = :key
          e.title = 'Moby Dick'
          e.author = 'Herman Melville'
          e.publisher = 'Penguin'
          e.address = 'New York'
          e.month = 'Nov'
          e.year = 1993
          e.parse_names
        end
      end
      
      it 'supports renaming! of field attributes' do
        @entry.rename!(:title => :foo)
        refute @entry.has_field?(:title)
        assert_equal 'Moby Dick', @entry[:foo]
      end

      it 'supports renaming of field attributes' do
        e = @entry.rename(:title => :foo)

        assert @entry.has_field?(:title)
        refute @entry.has_field?(:foo)

        assert e.has_field?(:foo)
        refute e.has_field?(:title)
        
        assert_equal 'Moby Dick', @entry[:title]
        assert_equal 'Moby Dick', e[:foo]
      end

      
      it 'supports citeproc export' do
        e = @entry.to_citeproc
        assert_equal 'book', e['type']
        assert_equal 'New York', e['publisher-place']
        assert_equal [1993,11], e['issued']['date-parts'][0]
        assert_equal 1, e['author'].length
        assert_equal 'Herman', e['author'][0]['given']
        assert_equal 'Melville', e['author'][0]['family']
      end
      
      describe 'given a filter' do
        before do
          @filter = Object.new
          def @filter.apply (value); value.is_a?(::String) ? value.upcase : value; end
        end
        
        it 'supports arbitrary conversion' do
          e = @entry.convert(@filter)
          assert_equal 'MOBY DICK', e.title
          assert_equal 'Moby Dick', @entry.title
        end

        it 'supports arbitrary in-place conversion' do
          @entry.convert!(@filter)
          assert_equal 'MOBY DICK', @entry.title
        end

        it 'supports conditional arbitrary in-place conversion' do
          @entry.convert!(@filter) { |k,v| k.to_s =~ /publisher/i  }
          assert_equal 'Moby Dick', @entry.title
          assert_equal 'PENGUIN', @entry.publisher
        end

        it 'supports conditional arbitrary conversion' do
          e = @entry.convert(@filter) { |k,v| k.to_s =~ /publisher/i  }
          assert_equal 'Moby Dick', e.title
          assert_equal 'PENGUIN', e.publisher
          assert_equal 'Penguin', @entry.publisher
        end
        
      end
      
      describe 'LaTeX filter' do
        before do
          @entry.title = 'M\\"{o}by Dick'
        end
        
        describe '#convert' do
          it 'converts LaTeX umlauts' do
            @entry.convert(:latex).title.must_be :==, 'Möby Dick'
          end
          
          it 'does not change the original entry' do
            e = @entry.convert(:latex)
            e.wont_be :==, @entry
            e.title.to_s.length.must_be :<, @entry.title.to_s.length
          end
        end

        describe '#convert!' do
          it 'converts LaTeX umlauts' do
            @entry.convert!(:latex).title.must_be :==, 'Möby Dick'
          end
          
          it 'changes the original entry in-place' do
            e = @entry.convert!(:latex)
            e.must_be :equal?, @entry
            e.title.to_s.length.must_be :==, @entry.title.to_s.length
          end
        end
        
      end
    end

    describe 'citeproc export' do
      before do
        @entry = Entry.new do |e|
          e.type = :book
          e.key = :key
          e.author = 'van Beethoven, Ludwig'
          e.parse_names
        end
      end
      
      it 'should use non-dropping-particle by default' do
        assert_equal 'van', @entry.to_citeproc['author'][0]['non-dropping-particle']
      end
      
      it 'should accept option to use non-dropping-particle' do
        assert_equal 'van', @entry.to_citeproc(:particle => 'non-dropping-particle')['author'][0]['non-dropping-particle']
      end
    end
    
    def test_simple
      bib = BibTeX::Bibliography.open(Test.fixtures(:entry), :debug => false)
      refute_nil(bib)
      assert_equal(BibTeX::Bibliography, bib.class)
      assert_equal(4, bib.data.length)
      assert_equal([BibTeX::Entry], bib.data.map(&:class).uniq)
      assert_equal('key:0', bib.data[0].key)
      assert_equal('key:1', bib.data[1].key)
      assert_equal('foo', bib.data[2].key)
      assert_equal(:book, bib.data[0].type)
      assert_equal(:article, bib.data[1].type)
      assert_equal(:article, bib.data[2].type)
      assert_equal('Poe, Edgar A.', bib.data[0][:author].to_s)
      assert_equal('Hawthorne, Nathaniel', bib.data[1][:author].to_s)
      assert_equal('2003', bib.data[0][:year])
      assert_equal('2001', bib.data[1][:year])
      assert_equal('American Library', bib.data[0][:publisher])
      assert_equal('American Library', bib.data[1][:publisher])
      assert_equal('Selected \\emph{Poetry} and `Tales\'', bib.data[0].title)
      assert_equal('Tales and Sketches', bib.data[1].title)
    end
  
    def test_ghost_methods
      bib = BibTeX::Bibliography.open(Test.fixtures(:entry), :debug => false)

      assert_equal 'Poe, Edgar A.', bib[0].author.to_s
    
      expected = 'Poe, Edgar Allen'
      bib.data[0].author = expected
    
      assert_equal expected, bib[0].author.to_s
    end
  
    def test_creation_simple    
      entry = BibTeX::Entry.new
      entry.type = :book
      entry.key = :raven
      entry.author = 'Poe, Edgar A.'
      entry.title = 'The Raven'
    
      assert_equal :book, entry.type
      assert_equal 'raven', entry.key
      assert_equal 'Poe, Edgar A.', entry.author
      assert_equal 'The Raven', entry.title
    end

    def test_creation_from_hash
      entry = BibTeX::Entry.new({
        :type => 'book',
        :key => :raven,
        :author => 'Poe, Edgar A.',
        :title => 'The Raven'
      })
    
      assert_equal :book, entry.type
      assert_equal 'raven', entry.key
      assert_equal 'Poe, Edgar A.', entry.author
      assert_equal 'The Raven', entry.title
    end

    def test_creation_from_block
      entry = BibTeX::Entry.new do |e|
        e.type = :book
        e.key = 'raven'
        e.author = 'Poe, Edgar A.'
        e.title = 'The Raven'
      end
    
      assert_equal :book, entry.type
      assert_equal 'raven', entry.key
      assert_equal 'Poe, Edgar A.', entry.author
      assert_equal 'The Raven', entry.title
    end
  
    def test_sorting
      entries = []
      entries << Entry.new({ :type => 'book', :key => 'raven3', :author => 'Poe, Edgar A.', :title => 'The Raven'})
      entries << Entry.new({ :type => 'book', :key => 'raven2', :author => 'Poe, Edgar A.', :title => 'The Raven'})
      entries << Entry.new({ :type => 'book', :key => 'raven1', :author => 'Poe, Edgar A.', :title => 'The Raven'})
      entries << Entry.new({ :type => 'book', :key => 'raven1', :author => 'Poe, Edgar A.', :title => 'The Aven'})
    
      entries.sort!
    
      assert_equal ['raven1', 'raven1', 'raven2', 'raven3'], entries.map(&:key)
      assert_equal ['The Aven', 'The Raven'], entries.map(&:title)[0,2]

    end
  
    describe 'default keys' do
      before {
        @e1 = Entry.new(:type => 'book', :author => 'Poe, Edgar A.', :title => 'The Raven', :editor => 'John Hopkins', :year => 1996)
        @e2 = Entry.new(:type => 'book', :title => 'The Raven', :editor => 'John Hopkins', :year => 1996)
        @e3 = Entry.new(:type => 'book', :author => 'Poe, Edgar A.', :title => 'The Raven', :editor => 'John Hopkins')
      }
  
      it 'should return "unknown-a" for an empty Entry' do
        Entry.new.key.must_be :==, 'unknown-a'
      end
  
      it 'should return a key made up of author-year-a if all fields are present' do
        @e1.key.must_be :==, 'poe1996a'
      end

      it 'should return a key made up of editor-year-a if there is no author' do
        @e2.key.must_be :==, 'john1996a'
      end

      it 'should return use the last name if the author/editor names have been parsed' do
        @e2.parse_names.key.must_be :==, 'hopkins1996a'
      end

      it 'skips the year if not present' do
        @e3.key.must_be :==, 'poe-a'
      end
    end
    
    describe 'when the entry is added to a Bibliography' do
      before {
        @e = Entry.new
        @bib = Bibliography.new
      }
      
      it 'should register itself with its key' do
        @bib << @e
        @bib.entries.keys.must_include @e.key
      end
      
      describe "when there is already an element registered with the entry's key" do
        before { @bib << Entry.new }
        
        it "should find a suitable key" do
          k = @e.key
          @bib << @e
          @bib.entries.keys.must_include @e.key
          k.wont_be :==, @e.key
        end
        
      end
    end
    
  end
end
