require 'helper'

module BibTeX
  class NameParserTest < Minitest::Spec
    describe "parse a number of entries having a 'van' or 'van den' name prefix" do
      before do
        @a = Names.parse('van den Bout, D. E.')
        @b = Names.parse('Van den Bout, D. E.')
      end

      it "should parse 'van den' part starting with lowercase letter" do
        assert_equal('van den Bout, D. E.', @a[0].to_s)
        assert_equal('van den', @a[0].prefix)
      end

      it "should parse 'Van den' part starting with uppercase letter" do
        assert_equal('Van den Bout, D. E.', @b[0].to_s)
        assert_equal('Van den', @b[0].prefix)
      end

      it 'should accept empty strings' do
        assert_equal '', Names.parse('').to_s
      end
    end

    describe 'parse a last name ending in a lowercase word before the comma (#149)' do
      it 'treats uppercase words followed by a lowercase word as the last name' do
        name = Name.parse("Rongiéras d'Usseau, Emmanuel")

        assert_equal [nil, "Rongiéras d'Usseau", 'Emmanuel'], [name.von, name.last, name.first]
      end

      it 'treats a single lowercase word before the comma as the last name' do
        name = Name.parse("d'Usseau, Emmanuel")

        assert_equal [nil, "d'Usseau", 'Emmanuel'], [name.von, name.last, name.first]
      end

      it 'still splits the von part off uppercase last names' do
        name = Name.parse('Meyer zu Selhausen, Karsten')

        assert_equal ['Meyer zu', 'Selhausen', 'Karsten'], [name.von, name.last, name.first]
      end
    end
  end
end
