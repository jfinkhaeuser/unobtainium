# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#

require 'socket'

module Unobtainium
  # @api private
  # Contains support code
  module Support
    ##
    # A bit of metaprogramming hackery to make a constant with possible domains
    # from Socket::Constants.
    if not constants.include?('DOMAINS')
      domains = []
      Socket::Constants.constants.each do |name|
        if name.to_s.start_with?("AF_")
          domains << name.to_s.gsub(/^AF_/, '').to_sym
        end
      end
      const_set('DOMAINS', domains.freeze)
    end

    ##
    # A port scanner for finding a free port for running e.g. a selenium
    # or appium server.
    module PortScanner
      # Retry a port this many times before failing
      MAX_RETRIES = 5

      # Delay each retry by this many seconds before trying again
      RETRY_DELAY = 0.5

      ##
      # Returns true if the port is open on the host, false otherwise.
      # @param host [String] host name or IP address
      # @param port [Integer] port number (1..65535)
      # @param domains [Array/Symbol] :INET, :INET6, etc. or an Array of
      #     these. Any from Socket::Constants::AF_* work. Defaults to
      #     %i[INET INET6].
      def port_open?(host, port, domains = %i[INET INET6])
        if port < 1 or port > 65535
          raise ArgumentError, "Port must be in range 1..65535!"
        end

        test_domains = nil
        if domains.is_a? Array
          test_domains = domains.dup
        else
          test_domains = [domains]
        end

        test_domains.each do |domain|
          if not DOMAINS.include?(domain)
            raise ArgumentError, "Domains must be one of #{DOMAINS}, or an Array "\
              "of them, but #{domain} isn't!"
          end
        end

        # Test a socket for each domain
        test_domains.each do |domain|
          addr = get_addr(host, port, domain)
          if addr.nil?
            next
          end

          if test_sockaddr(addr, domain)
            return true
          end
        end

        return false
      end

      ##
      # Scan a mixture of ranges and arrays of ports for a given host.
      # Return those that are open or closed, depending on the options
      # given.
      def scan(host, *args)
        # Argument checks
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

        if not %i[all first].include?(opts[:amount])
          raise ArgumentError, ":amount must be one of :all, :first!"
        end
        if not %i[open closed available].include?(opts[:for])
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

        if not open and %i[closed available].include?(test_for)
          return true
        end

        return false
      end

      # Create an address for the domain. That's a little convoluted, but it
      # avoids errors with trying to use INET addresses with INET6 and vice versa.
      def get_addr(host, port, domain)
        begin
          infos = Addrinfo.getaddrinfo(host, port, domain, :STREAM)
          infos.each do |info|
            if info.pfamily == Socket.const_get('PF_' + domain.to_s)
              return info.to_sockaddr
            end
          end
        rescue SocketError
          # Host does not resolve in this domain
          return nil
        end

        return nil
      end

      # Test a particular sockaddr
      def test_sockaddr(addr, domain)
        sock = Socket.new(domain, :STREAM)

        connected = false
        tries = MAX_RETRIES
        loop do
          begin
            sock.connect_nonblock(addr)
          rescue Errno::EINPROGRESS
            tries -= 1
            if tries <= 0
              # That's it, we've got enough.
              break
            end

            # The result of select doesn't matter. What matters is that we wait
            # for sock to become usable, or for the timeout to occur.
            IO.select([sock], [sock], nil, RETRY_DELAY)
          rescue Errno::EISCONN
            connected = true
            break
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            # Could not connect
            break
          rescue Errno::EINVAL, Errno::EAFNOSUPPORT
            # Unsupported protocol
            break
          end
        end

        sock.close

        return connected
      end
    end # module PortScanner
  end # module Support
end # module Unobtainium
