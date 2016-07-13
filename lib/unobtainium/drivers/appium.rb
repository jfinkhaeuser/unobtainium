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
    # Driver implementation wrapping the appium_lib gem.
    class Appium
      # Recognized labels for matching the driver
      LABELS = {
        ios: [:iphone, :ipad],
        android: [],
      }.freeze

      # Browser matches for some platforms
      # TODO: add many more matches
      BROWSER_MATCHES = {
        android: {
          chrome: {
            browserName: 'Chrome',
          },
        },
      }.freeze

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
          require 'appium_lib'
        rescue LoadError => err
          raise LoadError, "#{err.message}: you need to add "\
                "'appium_lib' to your Gemfile to use this driver!",
                err.backtrace
        end

        ##
        # Sanitize options, and expand the :browser key, if present.
        def resolve_options(label, options)
          # Normalize label and options
          normalized = normalize_label(label)
          options = ::Collapsium::UberHash.new(options || {})

          # The label specifies the platform, if no other platform is given.
          if options['caps.platformName']
            options['caps.platformName'] = normalized.to_s
          end

          # Make the appium driver behave a little more like Selenium by using
          # the :url key if the normalized label is remote, and setting
          # appropriate options.
          set_url = options['appium_lib.server_url']
          if set_url and not set_url == options['url']
            warn "You have the remote URL '#{set_url}' set in your options, "\
              "so we're not replacing it with '#{options['url']}'!"
          else
            options['appium_lib.server_url'] = options['url']
          end

          # If no app is given, but a browser is requested, we can supplement
          # some information
          options = supplement_browser(options)

          return label, options
        end

        ##
        # Create and return a driver instance
        def create(_, options)
          # Create the driver
          driver = ::Appium::Driver.new(options).start_driver
          return driver
        end

        private

        ##
        # If the driver options include a request for a browser, we can
        # supplement some missing specs in the options.
        def supplement_browser(options)
          # Can't do anything without a browser request.
          if options['browser'].nil?
            return options
          end
          browser = options['browser'].downcase.to_sym

          # Platform
          platform = options['caps.platformName'].to_s.downcase.to_sym

          # If we have supplement data matching the platform and browser, great!
          data = BROWSER_MATCHES[platform][browser]
          if data.nil?
            return options
          end

          # We do have to check that we're not overwriting any of the keys.
          data.each do |key, value|
            option_value = nil
            if options['caps'].key?(key)
              option_value = options['caps'][key]
            end

            if option_value.nil? or option_value == value
              next
            end
            raise ArgumentError, "You specified the browser option as, "\
              "'#{options['browser']}', but you also have the key "\
              "'#{key}' set in your requested capabilities. Use one or the "\
              "other."
          end

          # Merge, but also stringify symbol keys
          data.each do |key, value|
            options['caps'][key.to_s] = value
          end

          options
        end
      end # class << self
    end # class Selenium

  end # module Drivers
end # module Unobtainium
