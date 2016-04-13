# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#
require 'unobtainium'

require 'unobtainium/driver'
require 'unobtainium/config'
require 'unobtainium/runtime'

module Unobtainium
  ##
  # The World module combines other modules, defining simpler entry points
  # into the gem's functionality.
  module World
    ##
    # Modules can have class methods, too.
    module ClassMethods
      # Configuration related
      def config_file=(name)
        @config_file = name
      end

      def config_file
        return @config_file || "config/config.yml"
      end
    end # module ClassMethods
    extend ClassMethods

    ##
    # Return the global configuration, loaded from :config_file
    def config
      return ::Unobtainium::Runtime.instance.store_with_if(:config) do
        ::Unobtainium::Config.load_config(::Unobtainium::World.config_file)
      end
    end

    ##
    # Returns a driver instance with the given options. If no options are
    # provided, options from the global configuration are used.
    def driver(label = nil, options = nil)
      # Make sure we have a label for the driver
      if label.nil?
        label = config["driver"]
      end

      # Make sure we have options matching the driver
      if options.nil?
        options = config["drivers.#{label}"]
      end

      # The merged/extended options might define a "base"; that's the label
      # we need to use.
      if not options.nil? and not options["base"].nil?
        label = options["base"]
      end

      # The driver may modify the options; if so, we should let it do that
      # here. That way our key (below) is based on the expanded options.
      label, options = ::Unobtainium::Driver.sanitize_options(label, options)

      # Create a key for the label and options. This should always
      # return the same key for the same label and options.
      key = { label: label, options: options }
      require 'digest/sha1'
      key = Digest::SHA1.hexdigest(key.to_s)
      key = "driver-#{key}"

      # Only create a driver with this exact configuration once. Unfortunately
      # We'll have to bind the destructor to whatever configuration exists at
      # this point in time, so we have to create a proc here - whether the Driver
      # gets created or not.
      at_end = config.fetch("at_end", "quit")
      dtor = proc do |the_driver|
        if the_driver.nil?
          return
        end

        meth = at_end.to_sym
        the_driver.send(meth)
      end
      return ::Unobtainium::Runtime.instance.store_with_if(key, dtor) do
        ::Unobtainium::Driver.create(label, options)
      end
    end
  end # module World
end # module Unobtainium
