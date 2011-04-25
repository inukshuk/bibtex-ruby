require 'helper'

module BibTeX
  
  class BibliographyTest < MiniTest::Spec
    
    context 'a new Bibliography' do

      should 'not be nil' do
        assert Bibliography.new
      end

      should 'be empty' do
        assert Bibliography.new.empty?
      end

    end

  end
end