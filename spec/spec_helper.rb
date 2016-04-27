# Only start CodeClimate from travis
if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

# Always start SimpleCov
require 'simplecov'
SimpleCov.start do
  add_filter 'unobtainium/drivers'
end
