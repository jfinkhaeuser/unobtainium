# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#
require 'unobtainium'

require 'collapsium-config'

require 'unobtainium/driver'
require 'unobtainium/runtime'
require 'unobtainium/support/identifiers'

module Unobtainium
  ##
  # The World module combines other modules, defining simpler entry points
  # into the gem's functionality.
  module World

    ##
    # Modules can have class methods, too, but it's a little more verbose to
    # provide them.
    module ClassMethods
      # Set the configuration file
      def config_file=(name)
        ::Collapsium::Config.config_file = name
      end

      # @return [String] the config file path, defaulting to 'config/config.yml'
      def config_file
        return ::Collapsium::Config.config_file
      end

      # In order for Unobtainium::World to include Collapsium::Config
      # functionality, it has to be inherited when the former is
      # included...
      def included(klass)
        set_config_path_default

        klass.class_eval do
          include ::Collapsium::Config
        end
      end

      # ... and when it's extended.
      def extended(world)
        # :nocov:
        set_config_path_default

        world.extend(::Collapsium::Config)
        # :nocov:
      end

      def set_config_path_default
        # Override collapsium-config's default config path
        if ::Collapsium::Config.config_file == \
           ::Collapsium::Config::DEFAULT_CONFIG_PATH
          ::Collapsium::Config.config_file = 'config/config.yml'
        end
      end
    end # module ClassMethods
    extend ClassMethods

    include ::Unobtainium::Support::Identifiers

    ##
    # (see Driver#create)
    #
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
        bases = options["base"]

        # Collapsium config returns an Array of bases, but we really only want
        # one. We'll have to do the sensible thing and only use one of the bases
        # which also is a driver for the label. Since there's no better choice,
        # let's default to the first of those.
        bases.each do |base|
          if not base.start_with?(".drivers.")
            next
          end
          label = base.gsub(/^\.drivers\./, '')
          break
        end

        # Unfortunately, the "base" key may not be recognized by the drivers,
        # which could lead to errors down the road. Let's remove it; it's reserved
        # by the Config class, so drivers can't use it anyhow.
        options = options.dup
        options.delete("base")
      end

      # The driver may modify the options; if so, we should let it do that
      # here. That way our key (below) is based on the expanded options.
      label, options, _ = ::Unobtainium::Driver.resolve_options(label, options)

      # Create a key for the label and options. This should always
      # return the same key for the same label and options.
      key = options['unobtainium_instance_id']
      if key.nil?
        key = identifier('driver', label, options)
      end

      # Only create a driver with this exact configuration once. Unfortunately
      # We'll have to bind the destructor to whatever configuration exists at
      # this point in time, so we have to create a proc here - whether the Driver
      # gets created or not.
      at_end = config.fetch("at_end", "quit")
      dtor = proc do |the_driver|
        # :nocov:
        if the_driver.nil?
          return
        end

        # We'll rescue Exception here because we really want all destructors
        # to run.
        # rubocop:disable Lint/RescueException
        begin
          meth = at_end.to_sym
          the_driver.send(meth)
        rescue Exception => err
          puts "Exception in destructor: #{err}"
        end
        # rubocop:enable Lint/RescueException
        # :nocov:
      end
      return ::Unobtainium::Runtime.instance.store_with_if(key, dtor) do
        ::Unobtainium::Driver.create(label, options)
      end
    end
  end # module World
end # module Unobtainium
