# Always start SimpleCov
require 'simplecov'
SimpleCov.start do
  add_filter 'unobtainium/drivers'
  add_filter 'spec'
end
