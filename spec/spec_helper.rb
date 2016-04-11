require 'simplecov'
SimpleCov.start do
  add_filter 'unobtainium/drivers'
end

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
