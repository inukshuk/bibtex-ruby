require 'helper.rb'

module BibTeX
  class LexerTest < MiniTest::Spec

    should 'correctly scan a string literal' do
      assert_equal Lexer.new.analyse(%q(@string{ x = "foo" })).symbols, [:AT,:STRING,:LBRACE,:NAME,:EQ,:STRING_LITERAL,:RBRACE,false]
    end
 
  end
end