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

          # At this point, the :phantomjs field is canonical in that it will
          # be used to generate a :port and :url if necessary. That means we
          # can use it to create a stable ID, too.
          # This also implies that the :url field is pointless and should not
          # be part of the ID; it will be generated again later on.
          options.delete(:url)

          # We need to figure out what we have to do based on detecting whether
          # a port or some other option changed (or nothing did!)
          fix_ports(label, options)

          # We find a free port here, so there's a possibility it'll get used
          # before we run the server in #create. However, for the purpose of
          # resolving options that's necessary. So we'll just live with this
          # until it becomes a problem.
          if options['phantomjs.generated_port'].nil?
            if options['phantomjs.port'].nil?
              ports = scan(options['phantomjs.host'], *PORT_RANGES,
                           for: :available, amount: :first)
              if ports.empty?
                raise "Could not find an available port for the PhantomJS server!"
              end
              options['phantomjs.generated_port'] = ports[0]
            else
              options['phantomjs.generated_port'] = options['phantomjs.port']
            end
          end

          # Now we can't just use new_id because we might have found a new
          # port in the meantime. We'll have to generate yet another ID, and
          # use that.
          # Now before calculating this new ID, we'll run the options through
          # the super method again. This is to ensure that all keys have the
          # expected class *before* we perform this calculation.
          new_id = identifier('driver', label, options)
          options['unobtainium_instance_id'] = new_id

          # Now we can generate the :url field for Selenium's benefit; it's
          # just a copy of the canonical options.
          options[:url] = "#{options['phantomjs.scheme']}://"\
              "#{options['phantomjs.host']}:"\
              "#{options['phantomjs.generated_port']}"

          return label, options
        end

        ##
        # Create and return a driver instance
        def create(_, options)
          # :nocov:

          # Extract PhantomJS options
          host = options['phantomjs.host']
          port = options['phantomjs.port'] || options['phantomjs.generated_port']
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
          parsed_port = parsed.port.to_i
          from_parsed = {
            phantomjs: {
              scheme: parsed.scheme,
              host: parsed.host,
              port: nil,
            },
          }

          # Very special case: if the parsed port matches the generated port,
          # and the port is nil, we want to keep it that way for deduplication
          # purposes. See `#fix_ports` for how this interacts.
          port = options['phantomjs.port']
          generated_port = options['phantomjs.generated_port']
          if not (parsed_port == generated_port and port.nil?)
            from_parsed[:phantomjs][:port] = parsed_port
          end

          options.recursive_merge!(from_parsed, false)
        end

        def merge_defaults(options)
          defaults = {
            phantomjs: {
              scheme: 'http',
              host: 'localhost',
              port: nil,
              generated_port: nil,
            },
          }
          options.recursive_merge!(defaults, false)
        end

        def fix_ports(label, options)
          # Let's keep the old ID around and generate a new one, largely as
          # a checksum of the options.
          old_id = options.delete('unobtainium_instance_id')
          new_id = identifier('driver', label, options)

          # If the IDs don't match, it means some options changed. This may be
          # the port or another option:
          # #1 If IDs are the same and port is the same as generated port, we
          #    need not do anything.
          # #2 If IDs are the same and the ports differ, we have reached an
          #    undefined state. This should be impossible.
          # #3 If IDs differ and the ports are the same, some other option was
          #    changed. We need to generate a new port and new ID (and warn about
          #    this).
          # #4 If IDs differ and ports differ, a new port was set. We need to
          #    proceed with the new port and generate a new ID.
          port = options['phantomjs.port']
          generated_port = options['phantomjs.generated_port']

          if old_id == new_id and port == generated_port
            # #1 above, nothing to do.
          elsif old_id == new_id and port != generated_port
            # :nocov:
            # #2 above, raise hell
            if not port.nil?
              raise "This can't happen; the instance ID (checksum) is the same, "\
                "but the input differed: #{port} <-> #{generated_port}"
            end
            # :nocov:
          elsif old_id != new_id and port == generated_port
            # #3 above; nuke the ports and warn.
            if not port.nil? and not generated_port.nil?
              warn "Rejecting port #{port} and generating new port because "\
                "options changed."
            end
            options['phantomjs.port'] = nil
            options['phantomjs.generated_port'] = nil
          elsif old_id != new_id and port != generated_port
            # #4 above
            options['phantomjs.generated_port'] = nil
          else
            # :nocov:
            # Unreachable
            raise "This can't happen; we have four cases and handle each of "\
              "them. This line is unreachable. Please check the logic."
            # :nocov:
          end
        end
      end # class << self
    end # class PhantomJS
  end # module Drivers
end # module Unobtainium
