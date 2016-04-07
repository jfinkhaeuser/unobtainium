# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#
module Unobtainium
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
      }.freeze

      class << self
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
        # Create and return a driver instance
        def create(label, _)
          driver = ::Selenium::WebDriver.for(normalize_label(label))
          return driver
        end

        private

        ##
        # For a recognized label alias, returns a normalized label.
        def normalize_label(label)
          LABELS.each do |normalized, aliases|
            if label == normalized or aliases.include?(label)
              return normalized
            end
          end
          return nil
        end
      end # class << self
    end # class Selenium

  end # module Drivers
end # module Unobtainium
