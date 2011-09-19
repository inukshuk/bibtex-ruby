require 'helper'

module BibTeX
  
  class PreambleTest < MiniTest::Spec
    
    describe 'a new preamble instance' do
      before do
        @preamble = Preamble.new
      end
      
      it 'should not be nil' do
        assert @preamble
      end
    end
    
    describe 'given a set of @preambles' do
      before do
        @bib = BibTeX.open(Test.fixtures(:preamble))
        @preambles = @bib.preambles
      end
      
      it 'should support round-trips of all parsed preambles' do
        assert_equal %q[@preamble{ "This bibliography was created \today" }], @preambles[0].to_s
        assert_equal %q[@preamble{ "Bib\TeX" }], @preambles[1].to_s
        assert_equal %q[@preamble{ "Maintained by " # maintainer }], @preambles[2].to_s
      end

      it 'should support string replacement of preamble contents' do
        assert_equal %q["Maintained by " # maintainer], @preambles[2].value.to_s
        @bib.replace_strings
        assert_equal %q["Maintained by " # "Myself"], @preambles[2].value.to_s
        @bib.join_strings
        assert_equal 'Maintained by Myself', @preambles[2].value.to_s
      end
    end

  end
  
end