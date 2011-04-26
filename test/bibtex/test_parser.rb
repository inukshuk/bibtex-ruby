require 'helper.rb'

module BibTeX
  class ParserTest < MiniTest::Spec
    
    context 'given a set of valid @entries' do
      setup do
        @bib = Parser.new(:debug => false).parse(File.read(Test.fixtures(:entry)))
      end
      
      should 'return a Bibliography' do
        assert @bib
        refute @bib.empty?
      end
        
      should 'parse all entries' do
        assert_equal 3, @bib.length
      end
      
      should 'parse the key values' do
        assert_equal %w{ key:0 key:1 foo }.map(&:to_sym), @bib.map(&:key)
      end

      should 'parse the entry types' do
        assert_equal [:book, :article, :article], @bib.map(&:type)
      end
      
      should 'parse all values correctly' do
        assert_equal 'Poe, Edgar A.', @bib[:'key:0'].author
        assert_equal 'Hawthorne, Nathaniel', @bib[:'key:1'].author
        
        assert_equal '2003', @bib[:'key:0'].year
        assert_equal '2001', @bib[:'key:1'].year

        assert_equal 'American Library', @bib[:'key:0'].publisher
        assert_equal 'American Library', @bib[:'key:1'].publisher
        
        assert_equal %q[Selected \emph{Poetry} and `Tales'], @bib[:'key:0'].title
        assert_equal 'Tales and Sketches', @bib[:'key:1'].title
      end     
    end
    
    context 'given a set of explicit and implicit comments' do
      setup do
        @bib = Parser.new(:debug => false, :include => [:meta_comments]).parse(File.read(Test.fixtures(:comment)))
      end
      
      should 'parses all @comments' do
        assert_equal 2, @bib.comments.length
      end

      should 'parses all meta comments' do
        assert_equal 3, @bib.meta_comments.length
      end
      
      should 'parse @comment content as string' do
        assert_equal ' A comment can contain pretty much anything ', @bib.comments[0].content
        assert_equal %Q[\n@string{ foo = "bar" }\n\n@string{ bar = "foo" }\n], @bib.comments[1].content
      end 
    end
    
    context 'given a set of @preambles' do
      setup do
        @bib = Parser.new(:debug => false).parse(File.read(Test.fixtures(:preamble)))
      end
      
      should 'parse all @preambles' do
        assert_equal 3, @bib.preambles.length
      end
      
      should 'parse all contents' do
        assert_equal 'This bibliography was created \\today', @bib.preambles[0].content
        assert_equal 'Bib\\TeX', @bib.preambles[1].content
        assert_equal '"Maintained by " # maintainer', @bib.preambles[2].content
      end
    end
    
  end
end