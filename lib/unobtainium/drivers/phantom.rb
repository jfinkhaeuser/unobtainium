# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#

require 'collapsium'

require_relative './selenium'
require_relative '../support/util'
require_relative '../support/port_scanner'
require_relative '../support/runner'
require_relative '../support/identifiers'
require_relative '../runtime'

module Unobtainium
  # @api private
  # Contains driver implementations
  module Drivers

    ##
    # Driver implementation using the selenium-webdriver gem to connect to
    # PhantomJS.
    class Phantom < Selenium
      # Recognized labels for matching the driver
      LABELS = {
        phantomjs: [:headless, :phantom],
      }.freeze

      # Port scanning ranges (can also be arrays or single port numbers.
      PORT_RANGES = [
        9134,
        8080,
        8000..8079,
        8081..10000,
        1025..7999,
        10001..65535,
      ].freeze

      # Timeout for waiting for connecting to PhantomJS server, in seconds
      CONNECT_TIMEOUT = 60

      class << self
        include ::Unobtainium::Support::Utility
        include ::Unobtainium::Support::PortScanner
        include ::Unobtainium::Support::Identifiers

        ##
        # Ensure that the driver's preconditions are fulfilled.
        def ensure_preconditions(_, _)
          super
          begin
            require 'phantomjs'
          rescue LoadError => err
            raise LoadError, "#{err.message}: you need to add "\
                  "'phantomjs' to your Gemfile to use this driver!",
                  err.backtrace
          end
        end

        ##
        # Mostly provides webdriver-specific options for PhantomJS
        def resolve_options(label, options)
          label, options = super

          options = ::Collapsium::UberHash.new(options)

          # If a URL is already provided, we should respect this.
          merge_url(options)

          # Provide defaults for webdriver host and port.
          merge_defaults(options)

          # We want this driver to know and set its own instance ID, so as to
          # avoid lots of instances talking to lots of different ports.
          if not options['unobtainium_instance_id']
            options['unobtainium_instance_id'] = identifier('driver', label,
                                                            options)
          end

          # We find a free port here, so there's a possibility it'll get used
          # before we run the server in #create. However, for the purpose of
          # resolving options that's necessary. So we'll just live with this
          # until it becomes a problem.
          if options['phantomjs.port'].nil?
            ports = scan(options['phantomjs.host'], *PORT_RANGES,
                         for: :available, amount: :first)
            if ports.empty?
              raise "Could not find an available port for the PhantomJS server!"
            end
            options['phantomjs.port'] = ports[0]
          end

          # Now override connection options for Selenium
          options[:url] = "#{options['phantomjs.scheme']}://"\
              "#{options['phantomjs.host']}:"\
              "#{options['phantomjs.port']}"

          return label, options
        end

        ##
        # Create and return a driver instance
        def create(_, options)
          # :nocov:

          # Extract PhantomJS options
          host = options['phantomjs.host']
          port = options['phantomjs.port']
          opts = options.dup
          opts.delete('phantomjs')

          # Start PhantomJS server, if it isn't already running
          conn_str = "#{host}:#{port}"
          runner = ::Unobtainium::Runtime.instance.store_with_if(conn_str) do
            ::Unobtainium::Support::Runner.new(conn_str,
                                               Phantomjs.path,
                                               "--webdriver=#{conn_str}")
          end
          runner.start

          # Wait for the server to open a port.
          timeout = CONNECT_TIMEOUT
          while timeout > 0 and not port_open?(host, port)
            sleep 1
            timeout -= 1
          end
          if timeout <= 0
            runner.kill
            out = runner.stdout.read
            err = runner.stderr.read
            runner.reset

            raise "Timeout waiting to connect to PhantomJS!\n"\
              "STDOUT: #{out}\n"\
              "STDERR: #{err}"
          end

          # Run Selenium against server
          driver = ::Selenium::WebDriver.for(:remote, opts)
          return driver

          # :nocov:
        end

        private

        def merge_url(options)
          if not options[:url]
            return
          end

          require 'uri'
          parsed = URI.parse(options[:url])
          from_parsed = {
            phantomjs: {
              scheme: parsed.scheme,
              host: parsed.host,
              port: parsed.port.to_i,
            },
          }
          options.recursive_merge!(from_parsed, false)
        end

        def merge_defaults(options)
          defaults = {
            phantomjs: {
              scheme: 'http',
              host: 'localhost',
              port: nil,
            },
          }
          options.recursive_merge!(defaults, false)
        end
      end # class << self
    end # class PhantomJS
  end # module Drivers
end # module Unobtainium
