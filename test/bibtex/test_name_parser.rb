require 'helper'

module BibTeX
  class NameParserTest < MiniTest::Spec

    context "parse a number of entries having a 'van' or 'van den' name prefix" do
      setup do
        @a = Names.parse('van den Bout, D. E.')
        @b = Names.parse('Van den Bout, D. E.')
      end

      should "parse 'van den' part starting with lowercase letter" do
        assert_equal(@a[0].to_str, "van den Bout, D. E.")
        assert_equal(@a[0].prefix, "van den")
      end

      should "parse 'Van den' part starting with uppercase letter" do
        assert_equal(@b[0].to_str, "Van den Bout, D. E.")
        assert_equal(@b[0].prefix, "Van den")
      end

    end

  end
end