require 'helper'

module BibTeX
  
  class PreambleTest < MiniTest::Spec
    
    context 'a new preamble instance' do
      setup do
        @preamble = Preamble.new
      end
      
      should 'not be nil' do
        assert @preamble
      end
    end
    
    context 'given a set of @preambles' do
      setup do
        @bib = BibTeX.open(Test.fixtures(:preamble))
        @preambles = @bib.preambles
      end
      
      should 'support round-trips of all parsed preambles' do
        assert_equal %q[@preamble{ "This bibliography was created \today" }], @preambles[0].to_s
        assert_equal %q[@preamble{ "Bib\TeX" }], @preambles[1].to_s
        assert_equal %q[@preamble{ "Maintained by " # maintainer }], @preambles[2].to_s
      end

      should 'support string replacement of preamble contents' do
        assert_equal %q["Maintained by " # maintainer], @preambles[2].value.to_s
        @bib.replace_strings
        assert_equal %q["Maintained by " # "Myself"], @preambles[2].value.to_s
        @bib.join_strings
        assert_equal 'Maintained by Myself', @preambles[2].value.to_s
      end
    end

  end
  
end