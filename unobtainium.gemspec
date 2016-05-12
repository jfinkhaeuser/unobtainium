# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'unobtainium/version'

# rubocop:disable Style/UnneededPercentQ, Style/ExtraSpacing
# rubocop:disable Style/SpaceAroundOperators
Gem::Specification.new do |spec|
  spec.name          = "unobtainium"
  spec.version       = Unobtainium::VERSION
  spec.authors       = ["Jens Finkhaeuser"]
  spec.email         = ["jens@finkhaeuser.de"]
  spec.description   = %q(
    Unobtainium wraps Selenium and Appium in a simple driver abstraction so that
    test code can more easily cover desktop browsers, mobile browsers and mobile
    apps.

    Some additional useful functionality for the maintenance of test suites is
    also added.
  )
  spec.summary       = %q(
    Obtain the unobtainable: test code covering multiple platforms
  )
  spec.homepage      = "https://github.com/jfinkhaeuser/unobtainium"
  spec.license       = "MITNFA"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0'

  spec.requirements  = "Either or all of 'selenium-webdriver', 'appium_lib', "\
                       "'phantomjs'"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rubocop", "~> 0.40"
  spec.add_development_dependency "rake", "~> 11.1"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "simplecov", "~> 0.11"
  spec.add_development_dependency "yard", "~> 0.8"
  spec.add_development_dependency "appium_lib"
  spec.add_development_dependency "selenium-webdriver"
  spec.add_development_dependency "phantomjs"
  spec.add_development_dependency "cucumber"

  spec.add_dependency "sys-proctable", "~> 1.0"
  spec.add_dependency "collapsium-config", "~> 0.1"
end
# rubocop:enable Style/SpaceAroundOperators
# rubocop:enable Style/UnneededPercentQ, Style/ExtraSpacing
