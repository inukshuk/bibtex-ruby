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
  end
end
