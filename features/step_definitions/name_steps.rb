When /^I parse the name "([^"]*)"$/ do |string|
  @name = BibTeX::Name.parse(string)
end

Then /^the parts should be:$/ do |table|
  table.hashes.each do |row|
    row.each do |part, value|
      assert_equal value, @name.send(part)
    end
  end
end