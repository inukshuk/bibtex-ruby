Given /^the bibliography:$/ do |string|
  @bibliography = BibTeX.parse(string)
end

When /^I parse the following file:$/ do |string|
  @bibliography = BibTeX.parse(string)
end

When /^I search for "([^"]*)"$/ do |query|
  @result = @bibliography.query(query)
end

When /^I search for :(.+)$/ do |query|
  @result = @bibliography.query(query.to_sym)
end

When /^I search for \/(.+)\/$/ do |query|
  @result = @bibliography.query(Regexp.new(query))
end

Then /^my bibliography should contain the following objects:$/ do |table|
  @bibliography.each_with_index do |object, index|
    table.hashes[index].each_pair do |key, value|
      assert_equal value, object.send(key).to_s
    end
  end
end

Then /^my bibliography should contain these (\w+):$/ do |type, table|
  @bibliography.q("@#{type.chomp!('s')}").zip(table.hashes).each do |object, expected|
    expected.each_pair do |key, value|
      assert_equal value, object.send(key).to_s
    end
  end
end

Then /^my bibliography should contain the following numbers of elements:$/ do |table|
  counts = table.hashes.first
  counts[[]] = counts.delete('total') if counts.has_key?('total')
  counts.each_pair do |type, length|
    assert_equal length.to_i, @bibliography.find_by_type(type).length
  end
end

Then /^my bibliography should contain an entry with key "([^"]*)"$/ do |key|
  refute_nil @bibliography[key.to_s]
end

Then /^my bibliography should not contain an entry with key "([^"]*)"$/ do |key|
  assert_nil @bibliography[key.to_sym]
end

Then /^there should be exactly (\d+) match(?:es)?$/ do |matches|
  assert_equal matches.to_i, @result.length
end


Then /^my bibliography should contain (\d+) (\w+) published in (\d+)$/ do |count, type, year|
  assert_equal @bibliography.q("@#{type.chomp!('s')}[year=#{year}]").length, count.to_i
end

Then /^my bibliography should contain an? (\w+) with id "([^"]*)"$/ do |type, id|
  assert_equal @bibliography[id.to_sym].type, type.to_sym
end