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

When /^I (replace|join) all strings(?: in my bibliography)$/ do |method|
  @bibliography.send("#{method}_strings")
end

When /^I replace and join all strings(?: in my bibliography)$/ do
  @bibliography.replace_strings.join_strings
end

When /^I convert all entries using the filter "([^"]*)"$/ do |filter|
  @bibliography.convert(filter)
end


Then /^my bibliography should contain the following objects:$/ do |table|
  @bibliography.each_with_index do |object, index|
    table.hashes[index].each_pair do |key, value|
      assert_equal value, object.send(key).to_s
    end
  end
end

Then /^my bibliography should contain th(?:ese|is) (\w+):$/ do |type, table|
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

Then /^my bibliography should contain an entry with (?:key|id) "([^"]*)"$/ do |key|
  refute_nil @bibliography[key.to_s]
end

Then /^my bibliography should contain an entry with (?:key|id) "([^"]*)" and a?n? (\w+) value of "([^"]*)"$/ do |key,field,value|
  refute_nil @bibliography[key.to_s]
  assert_equal value, @bibliography[key.to_s][field].to_s
end


Then /^my bibliography should not contain an entry with (?:key|id) "([^"]*)"$/ do |key|
  assert_nil @bibliography[key.to_sym]
end

Then /^there should be exactly (\d+) match(?:es)?$/ do |matches|
  assert_equal matches.to_i, @result.length
end


Then /^my bibliography should contain (\d+) (\w+)$/ do |count, type|
  assert_equal count.to_i, @bibliography.q("@#{type.chomp('s')}").length
end

Then /^my bibliography should contain (\d+) (\w+) published in (\d+)$/ do |count, type, year|
  assert_equal count.to_i, @bibliography.q("@#{type.chomp('s')}[year=#{year}]").length
end

Then /^my bibliography should contain an? (\w+) with id "([^"]*)"$/ do |type, id|
  assert_equal @bibliography[id.to_sym].type, type.to_sym
end

Then /^the string "([^"]*)" should be "([^"]*)"$/ do |key, value|
  assert_equal value, @bibliography.strings[key.to_sym].v.to_s
end

Then /^the entry with key "([^"]*)" should have a field "([^"]*)" with the value "([^"]*)"$/ do |key, field, value|
  assert_equal value, @bibliography[key.to_sym][field.to_sym].to_s
end