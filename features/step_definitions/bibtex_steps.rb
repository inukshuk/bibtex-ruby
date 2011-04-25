When /^I parse the following file:$/ do |string|
  @bibliography = BibTeX.parse(string)
end

Then /^my bibliography should contain the following objects:$/ do |table|
  @bibliography.each_with_index do |object, index|
    assert_equal object.type, table.hashes[index][:type]
    assert_equal object.content, table.hashes[index][:content]
  end
end