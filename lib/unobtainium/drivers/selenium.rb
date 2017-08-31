# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#

require 'collapsium'

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
        firefox: %i[ff],
        internet_explorer: %i[internetexplorer explorer ie],
        safari: [],
        chrome: [],
        chromium: [],
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
          # Normalize label and options
          normalized = normalize_label(label)
          options = ::Collapsium::UberHash.new(options || {})

          # Merge 'caps' and 'desired_capabilities', letting the latter win
          options[:desired_capabilities] =
            ::Collapsium::UberHash.new(options['caps'])
                                  .recursive_merge(options[:caps])
                                  .recursive_merge(options[:desired_capabilities])
          options.delete(:caps)
          options.delete('caps')

          # Chromium is chrome, but with a different binary. Help with that.
          label, options = supplement_chromium(normalized, options)

          # Selenium expects the first level keys to be symbols *only*, so
          # indifferent access from UberHash isn't good. We have to fix that.
          options = fix_options(options)

          return label, options
        end

        ##
        # Create and return a driver instance
        def create(label, options)
          # :nocov:
          driver = ::Selenium::WebDriver.for(normalize_label(label), options)
          return driver
          # :nocov:
        end

        private

        ##
        # If the driver was :chromium, try to use the :chrome driver with
        # options pointing to the chromium binary.
        def supplement_chromium(label, options)
          # Only applies to :chromium
          if :chromium != label
            return label, options
          end

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
          if binary.nil?
            return label, options
          end

          set_binary = options['desired_capabilities.chromeOptions.binary']
          if set_binary and set_binary != binary
            # There's already a binary set. We should warn about this, but
            # otherwise leave this choice.
            warn "You have the chrome binary '#{set_binary}' set in your "\
              "options, so we're not replacing it with '#{binary}'!"
          else
            options['desired_capabilities.chromeOptions.binary'] = binary
          end

          # Selenium doesn't recognize :chromium, but :chrome with the above
          # options works.
          return :chrome, options
        end

        # Selenium expects the first level keys to be symbols *only*, so
        # indifferent access from UberHash isn't good. We have to fix that.
        def fix_options(options)
          result = {}

          options.each do |key, value|
            result[key.to_sym] = value
          end

          return result
        end
      end # class << self
    end # class Selenium

  end # module Drivers
end # module Unobtainium
