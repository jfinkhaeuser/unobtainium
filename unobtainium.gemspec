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
    test code can more easily cover:

      - Desktop browsers
      - Mobile browsers
      - Mobile apps

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

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rubocop", "~> 0.39"
  #  spec.add_development_dependency "rake"
  #  spec.add_development_dependency "simplecov"
  #
  #  spec.add_dependency "thor", "~> 0.19"
  #  spec.add_dependency "facets", "~> 2.9"
  #  spec.add_dependency "json", "~> 1.8"
  #  spec.add_dependency "faraday", "~> 0.9"
  #  spec.add_dependency "faraday_middleware", "~> 0.9"
  #  spec.add_dependency "faraday_json", "~> 0.1"
  #  spec.add_dependency "multi_xml", "~> 0.5"
  #  spec.add_dependency "teelogger", "~> 0.5"
  #  spec.add_dependency "minitest", "~> 5.5"
end
# rubocop:enable Style/SpaceAroundOperators
# rubocop:enable Style/UnneededPercentQ, Style/ExtraSpacing

