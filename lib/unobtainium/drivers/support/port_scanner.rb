# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#
module Unobtainium
  # @api private
  # Contains driver implementations
  module Drivers
    ##
    # A port scanner for finding a free port for running e.g. a selenium
    # or appium server.
    module PortScanner
      ##
      # Returns true if the port is open on the host, false otherwise.
      # @param host [String] host name or IP address
      # @param port [Integer] port number (1..65535)
      def port_open?(host, port)
        if port < 1 or port > 65535
          raise ArgumentError, "Port must be in range 1..65535!"
        end

        require 'socket'
        sock = Socket.new(:INET, :STREAM)
        addr = Socket.sockaddr_in(port, host)
        return 0 == sock.connect(addr)
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
        return false
      ensure
        if not sock.nil?
          sock.close
        end
      end

      ##
      # Scan a mixture of ranges and arrays of ports for a given host.
      # Return those that are open or closed, depending on the options
      # given.
      def scan(host, *args)
        # Argument checks
        if host.nil? or host.empty?
          raise ArgumentError, "Must provide a host name or IP!"
        end

        if args.empty?
          raise ArgumentError, "Need at least one port to scan!"
        end

        args.each do |item|
          if not item.respond_to?(:each) and not item.respond_to?(:to_i)
            raise ArgumentError, "The argument '#{item}' to #scan is not a "\
              "Range, Array or convertible to Integer, aborting!"
          end
        end

        # If the last argument is a Hash, treat it as options.
        opts = {}
        if args.last.is_a? Hash
          opts = args.pop
        end
        opts = { for: :open, amount: :all }.merge(opts)

        if not [:all, :first].include?(opts[:amount])
          raise ArgumentError, ":amount must be one of :all, :first!"
        end
        if not [:open, :closed, :available].include?(opts[:for])
          raise ArgumentError, ":for must beone of :open, :closed, :available!"
        end

        return run_scan(host, opts, *args)
      end

      private

      def run_scan(host, opts, *args)
        results = []

        # Iteratively scan all arguments
        args.each do |item|
          if item.respond_to?(:to_i)
            item_i = item.to_i
            if test_port(host, item_i, opts[:for])
              results << item_i
              if opts[:amount] == :first
                return results
              end
            end
            next
          end

          item.each do |port|
            if not test_port(host, port, opts[:for])
              next
            end

            results << port
            if opts[:amount] == :first
              return results
            end
          end
        end

        return results
      end

      def test_port(host, port, test_for)
        open = port_open?(host, port)

        if open and :open == test_for
          return true
        end

        if not open and [:closed, :available].include?(test_for)
          return true
        end

        return false
      end
    end # module PortScanner
  end # module Drivers
end # module Unobtainium
