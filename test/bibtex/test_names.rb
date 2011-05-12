require 'helper'

module BibTeX
  class NamesTest < MiniTest::Spec
    
    context 'string behaviour' do
      setup do
        @name = Name.new(:first => 'Charles Louis Xavier Joseph', :prefix => 'de la', :last => 'Vallee Poussin', :suffix => 'Jr.')
      end
      should 'implement upcase!' do
        assert_equal 'DE LA VALLEE POUSSIN, JR., CHARLES LOUIS XAVIER JOSEPH', @name.upcase!.to_s
      end
      should 'implement downcase!' do
        assert_equal 'de la vallee poussin, jr., charles louis xavier joseph', @name.downcase!.to_s
      end
      should 'implement gsub!' do
        assert_equal 'dX la VallXX PoussXn, Jr., CharlXs LouXs XavXXr JosXph', @name.gsub!(/[ei]/, 'X').to_s        
      end
      
    end
    
  end
end