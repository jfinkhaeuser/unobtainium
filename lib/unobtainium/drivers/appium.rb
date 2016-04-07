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
    # Driver implementation wrapping the appium_lib gem.
    class Appium
      # Recognized labels for matching the driver
      LABELS = {
        appium: [],
        ios: [:iphone, :ipad],
        android: [],
      }.freeze

      # Browser matches for some platforms
      # TODO: add many more matches
      BROWSER_MATCHES = {
        android: {
          chrome: {
            appPackage: 'com.android.chrome',
            appActivity: 'com.google.android.apps.chrome.Main',
          },
        },
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
          require 'appium_lib'
        rescue LoadError => err
          raise LoadError, "#{err.message}: you need to add "\
                "'appium_lib' to your Gemfile to use this driver!",
                err.backtrace
        end

        ##
        # Create and return a driver instance
        def create(label, options)
          # The label specifies the platform, if no other platform is given.
          normalized = normalize_label(label)

          if not options.is_a? Hash
            options = {}
          end
          if not options['caps'].is_a? Hash
            options['caps'] = {}
          end

          if options['caps']['platformName'].nil?
            options['caps']['platformName'] = normalized.to_s
          end

          # If no app is given, but a browser is requested, we can supplement
          # some information
          options = supplement_browser(options)

          # Create the driver
          driver = ::Appium::Driver.new(options).start_driver
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
          platform = options['caps']['platformName'].to_s.downcase.to_sym

          # If we have supplement data matching the platform and browser, great!
          data = BROWSER_MATCHES[platform][browser]
          if data.nil?
            return options
          end

          # We do have to check that we're not overwriting any of the keys.
          data.keys.each do |key|
            key_s = key.to_s
            if not options['caps'].key?(key) and not options['caps'].key?(key_s)
              next
            end
            raise ArgumentError, "You specified the browser option as, "\
              "'#{options['browser']}', but you also have the key "\
              "'#{key}' set in your requested capabilities. Use one or the"\
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
