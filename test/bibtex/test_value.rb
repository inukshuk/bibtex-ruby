require 'helper.rb'

module BibTeX
  class ValueTest < MiniTest::Spec
    
    context "when empty" do
      should "be equal to an empty string" do
        assert Value.new == ''
      end
      should "be empty" do
        assert Value.new.empty?
      end
      should "match an empty pattern" do
        assert Value.new =~ //
      end
    end
    
    context "#join" do
      should "work" do
        assert_equal '', Value.new.join.to_s
        assert_equal 'foo', Value.new('foo').join.to_s
        assert_equal 'foobar', Value.new('foo', 'bar').join.to_s
        assert_equal 'foobar', Value.new(['foo', 'bar']).join.to_s
      end
    end
    
  end
end