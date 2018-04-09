# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016-2017 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'unobtainium/version'

# rubocop:disable Style/UnneededPercentQ, Layout/ExtraSpacing
# rubocop:disable Layout/SpaceAroundOperators
Gem::Specification.new do |spec|
  spec.name          = "unobtainium"
  spec.version       = Unobtainium::VERSION
  spec.authors       = ["Jens Finkhaeuser", "Jana Rekittke"]
  spec.email         = ["jens@finkhaeuser.de", "jrekittke@babbel.com"]
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

  spec.required_ruby_version = '>= 2.2'

  spec.requirements  = "Either or all of 'selenium-webdriver', 'appium_lib', "\
                       "'phantomjs'"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 11.3"
  spec.add_development_dependency "rspec", "~> 3.7"
  spec.add_development_dependency "simplecov", "~> 0.16"
  spec.add_development_dependency "yard", "~> 0.9", ">= 0.9.12"
  spec.add_development_dependency "appium_lib", ">= 9.1"
  spec.add_development_dependency "selenium-webdriver"
  spec.add_development_dependency "chromedriver-helper"
  spec.add_development_dependency "phantomjs"
  spec.add_development_dependency "cucumber"

  spec.add_dependency "sys-proctable", "~> 1.2"
  spec.add_dependency "ptools", "~> 1.3"
  spec.add_dependency "collapsium", "~> 0.10"
  spec.add_dependency "collapsium-config", "~> 0.7"
end
# rubocop:enable Layout/SpaceAroundOperators
# rubocop:enable Style/UnneededPercentQ, Layout/ExtraSpacing
