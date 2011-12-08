# coding: utf-8

require 'helper'

module BibTeX
  class NamesTest < MiniTest::Spec
    
    describe 'string behaviour' do
      before do
        @name = Name.new(:first => 'Charles Louis Xavier Joseph', :prefix => 'de la', :last => 'Vallee Poussin', :suffix => 'Jr.')
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
    
		describe "conversions" do
      before do
        class UpcaseAll < BibTeX::Filter
          def apply (value)
            value.upcase
          end
        end
      end
      
      describe "#convert" do
        it "converts the value when given a filter instance" do
					Names.parse('Poe and Hawthorne').convert(UpcaseAll.instance).to_s.must_be :==, 'POE and HAWTHORNE'
        end

				it "converts LaTeX umlauts" do
					Names.parse("S{\\o}ren Kirkegaard and Emmanuel L\\'evinas").convert(:latex).to_s.must_be :==, 'Kirkegaard, Søren and Lévinas, Emmanuel'
				end
			end

		end
    
  end
end