
# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#
module Unobtainium

  ##
  # Creating a Driver instance creates either an Appium or Selenium driver
  # depending on the arguments, and delegates all else to the underlying
  # implementation.
  #
  # It's possible to add more drivers, but Appium and Selenium are the main
  # targets.
  class Driver
    ############################################################################
    # Class methods
    class << self
      ##
      # Create a driver instance with the given arguments
      def create(*args)
        new(*args)
      end

      private :new
    end # class << self

    ############################################################################
    # Public methods
    attr_reader :label, :options, :impl

    private

    ##
    # Initializer
    def initialize(*args)
      # Sanitize options
      @label, @options = sanitize_options(*args)

      # Load drivers
      load_drivers

      # Determine the driver class, if any
      driver_klass = get_driver(@label)
      if not driver_klass
        raise LoadError, "No driver implementation matching #{@label} found, "\
          "aborting!"
      end

      # Perform precondition checks of the driver class
      driver_klass.ensure_preconditions(@label, @options)

      # Great, instanciate!
      @impl = driver_klass.create(@label, @options)
    end

    # Class variables have their place, rubocop... still, err on the strict
    # side and just skip this check here.
    # rubocop:disable Style/ClassVars
    @@drivers = {}
    # rubocop:enable Style/ClassVars

    # Methods that drivers must implement
    DRIVER_METHODS = [
      :matches?,
      :ensure_preconditions,
      :create
    ].freeze

    ##
    # FIXME
    def sanitize_options(*args)
      load_drivers
      require 'pp'
      pp args
    end

    ##
    # Load drivers.
    def load_drivers
      # TODO: add load path for external drivers, or let them be specified via
      #       the driver environment/config variables.
      pattern = File.join(File.dirname(__FILE__), 'drivers', '*.rb')
      Dir.glob(pattern).each do |fpath|
        # Determine class name from file name
        fname = File.basename(fpath, '.rb')
        fname = fname.split('_').map(&:capitalize).join

        begin
          require fpath
          klassname = 'Unobtainium::Drivers::' + fname
          klass = Object.const_get(klassname)
          klass_methods = klass.methods - klass.instance_methods - Object.methods

          if DRIVER_METHODS - klass_methods != []
            raise LoadError, "Driver #{klassname} is not implementing all of "\
              "#{DRIVER_METHODS}, aborting!"
          end

          if @@drivers.include?(klass) and @@drivers[klass] != fpath
            raise LoadError, "Driver #{klassname} is duplicated in file "\
              "'#{fpath}'; previous definition is here: "\
              "'#{@@drivers[klass]}'"
          end
          @@drivers[klass] = fpath

        rescue LoadError => err
          raise LoadError, "#{err.message}: unknown problem loading driver, "\
            "aborting!"
        rescue NameError => err
          raise LoadError, "#{err.message}: unknown problem loading driver, "\
            "aborting!"
        end
      end
    end

    ##
    # Out of the loaded drivers, returns the one matching the label (if any)
    def get_driver(label)
      # Of all the loaded classes, choose the first (unsorted) to match the
      # requested driver label
      impl = nil
      @@drivers.keys.each do |klass|
        if klass.matches?(label)
          impl = klass
          break
        end
      end

      return impl
    end
  end # class Driver
end # module Unobtainium
