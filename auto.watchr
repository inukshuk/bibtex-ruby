require 'autowatchr'

Autowatchr.new(self) do |config|
	config.lib_dir  = 'lib'
	config.test_dir = 'test'
end
