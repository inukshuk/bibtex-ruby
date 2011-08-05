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

      should 'handle strange keys' do
        input = "@Misc{George Martin06,title = {FEAST FOR CROWS}}"
        bib = Parser.new(:debug => false, :strict => false).parse(input)
        assert_equal :"George Martin06", bib.first.key
        assert bib[:"George Martin06"]
      end

      should 'parse the entry types' do
        assert_equal [:book, :article, :article], @bib.map(&:type)
      end
      
      should 'parse all values correctly' do
        assert_equal 'Poe, Edgar A.', @bib[:'key:0'].author.to_s
        assert_equal 'Hawthorne, Nathaniel', @bib[:'key:1'].author.to_s
        
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
        @bib = Parser.new(:debug => false, :include => [:meta_content]).parse(File.read(Test.fixtures(:comment)))
      end
      
      should 'parses all @comments' do
        assert_equal 2, @bib.comments.length
      end

      should 'parses all meta content' do
        assert_equal 3, @bib.meta_contents.length
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
        assert_equal 'This bibliography was created \\today', @bib.preambles[0].value.to_s
        assert_equal 'Bib\\TeX', @bib.preambles[1].value.to_s
        assert_equal '"Maintained by " # maintainer', @bib.preambles[2].value.to_s
      end
    end
    
    context 'given an entry containing a multi-line literals' do
      setup do
        @braces = %Q[@TechReport{key,\n  author = {Donald,\n     Duck}\n}]
        @string = %Q[@TechReport{key,\n  author = "Donald,\n     Duck"\n}]
      end
      
      should 'parse string literals' do
        refute_nil Parser.new.parse(@string)[:key]
      end

      should 'parse braced literals' do
        refute_nil Parser.new.parse(@braces)[:key]
      end

    end
    
  end
end
