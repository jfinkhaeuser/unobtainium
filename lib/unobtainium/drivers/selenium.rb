# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#

require_relative './support/util'

module Unobtainium
  # @api private
  # Contains driver implementations
  module Drivers

    ##
    # Driver implementation wrapping the selenium-webdriver gem.
    class Selenium
      # Recognized labels for matching the driver
      LABELS = {
        firefox: [:ff,],
        internet_explorer: [:internetexplorer, :explorer, :ie,],
        safari: [],
        chrome: [],
        chromium: [],
        remote: [],
      }.freeze

      class << self
        include ::Unobtainium::Drivers::Utility

        ##
        # Return true if the given label matches this driver implementation,
        # false otherwise.
        def matches?(label)
          return nil != normalize_label(label)
        end

        ##
        # Ensure that the driver's preconditions are fulfilled.
        def ensure_preconditions(_, _)
          require 'selenium-webdriver'
        rescue LoadError => err
          raise LoadError, "#{err.message}: you need to add "\
                "'selenium-webdriver' to your Gemfile to use this driver!",
                err.backtrace
        end

        ##
        # Selenium really wants symbol keys for the options
        def resolve_options(label, options)
          new_opts = {}

          if not options.nil?
            options.each do |key, value|
              new_opts[key.to_sym] = value
            end
          end

          options = new_opts

          return label, options
        end

        ##
        # Create and return a driver instance
        def create(label, options)
          driver = ::Selenium::WebDriver.for(normalize_label(label), options)
          return driver
        end
      end # class << self
    end # class Selenium

  end # module Drivers
end # module Unobtainium
