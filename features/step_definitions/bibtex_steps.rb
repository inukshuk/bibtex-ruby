Given /^the bibliography:$/ do |string|
  @bibliography = BibTeX.parse(string)
end

When /^I parse the following file:$/ do |string|
  @bibliography = BibTeX.parse(string)
end

When /^I search for "([^"]*)"$/ do |query|
  @result = @bibliography.find(query)
end

When /^I search for :(.+)$/ do |query|
  @result = @bibliography.find(query.to_sym)
end

When /^I search for \/(.+)\/$/ do |query|
  @result = @bibliography.find(Regexp.new(query))
end

Then /^my bibliography should contain the following objects:$/ do |table|
  @bibliography.each_with_index do |object, index|
    table.hashes[index].each_pair do |key, value|
      assert_equal value, object.send(key).to_s
    end
  end
end

Then /^my bibliography should contain the following numbers of elements:$/ do |table|
  counts = table.hashes.first
  counts['all'] = counts.delete('total') if counts.has_key?('total')
  counts.each_pair do |type, length|
    assert_equal length.to_i, @bibliography.find_by_type(type).length
  end
end

Then /^my bibliography should contain an entry with key "([^"]*)"$/ do |key|
  assert @bibliography[key]
end

Then /^my bibliography should not contain an entry with key "([^"]*)"$/ do |key|
  assert @bibliography[key].nil?
end

Then /^there should be exactly (\d+) match(?:es)?$/ do |matches|
  assert_equal matches.to_i, @result.length
end