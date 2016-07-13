# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#

require_relative '../support/util'

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
        selenium_remote: [:remote],
      }.freeze

      # When :chromium is selected, search for these executables. The
      # resulting label will be :chrome, but with an executable path
      # set in the options.
      CHROMIUM_EXECUTABLES = [
        'chromium-browser'
      ].freeze

      class << self
        include ::Unobtainium::Support::Utility

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

          normalized = normalize_label(label)
          if :chromium == normalized
            # Try to find a chromium binary
            binary = nil
            require 'ptools'
            CHROMIUM_EXECUTABLES.each do |name|
              location = File.which(name)
              if not location.nil?
                binary = location
                break
              end
            end

            # If we found a chromium binary, we can modify the options.
            # Otherwise, we don't do a thing and let selenium fail.
            if not binary.nil?
              if not options.key?(:desired_capabilities)
                options[:desired_capabilities] = {}
              end
              if not options[:desired_capabilities].key?('chromeOptions')
                options[:desired_capabilities]['chromeOptions'] = {}
              end
              if options[:desired_capabilities]['chromeOptions']['binary'] and not options[:desired_capabilities]['chromeOptions']['binary'] == binary
                # There's already a binary set. We should warn about this, but
                # otherwise leave this choice.
                warn "Not replacing the chrome binary '#{options[:desired_capabilities]['chromeOptions']['binary']}' with '#{binary}'!"
              else
                options[:desired_capabilities]['chromeOptions']['binary'] = binary
              end
            end

            # Selenium doesn't recognize :chromium, but :chrome with the above
            # options works.
            label = :chrome
          end

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
