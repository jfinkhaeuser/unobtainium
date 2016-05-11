
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
      # Create a driver instance with the given arguments.
      #
      # @param label [String, Symbol] Label for the driver to create. Driver
      #   implementations may accept normalized and alias labels, e.g.
      #   `:firefox, `:ff`, `:remote`, etc.
      # @param opts [Hash] Options passed to the driver implementation.
      def create(label, opts = nil)
        new(label, opts)
      end

      ##
      # Add a new driver implementation. The first parameter is the class
      # itself, the second should be a file path pointing to the file where
      # the class is defined. You would typically pass `__FILE__` for the second
      # parameter.
      #
      # Using file names lets us figure out whether the class is a duplicate,
      # or merely a second registration of the same class.
      #
      # Driver classes must implement the class methods listed in `DRIVER_METHODS`.
      #
      # @param klass (Class) Driver implementation class to register.
      # @param path (String) Implementation path of the driver class.
      def register_implementation(klass, path)
        # We need to deal with absolute paths only
        fpath = File.absolute_path(path)

        # Figure out if the class implements all the methods we need; we're not
        # checking for anything else.
        klass_methods = klass.methods - klass.instance_methods - Object.methods

        if DRIVER_METHODS - klass_methods != []
          raise LoadError, "Driver #{klass.name} is not implementing all of "\
            "the class methods #{DRIVER_METHODS}, aborting!"
        end

        # The second question is whether the same class is already known, or
        # whether a class with the same name but under a different location is
        # known.
        if @@drivers.include?(klass) and @@drivers[klass] != fpath
          raise LoadError, "Driver #{klass.name} is duplicated in file "\
            "'#{fpath}'; previous definition is here: "\
            "'#{@@drivers[klass]}'"
        end

        # If all of that was ok, we can register the implementation.
        @@drivers[klass] = fpath
      end

      ##
      # Add a new driver module. The first parameter is the class itself, the
      # second should be a file path pointing to the file where the class is
      # defined. You would typically pass `__FILE__` for the second parameter.
      #
      # Driver modules must implement the class methods listed in `MODULE_METHODS`.
      #
      # @param klass (Class) Driver implementation class to register.
      # @param path (String) Implementation path of the driver class.
      def register_module(klass, path)
        # We need to deal with absolute paths only
        fpath = File.absolute_path(path)

        # Figure out if the class implements all the methods we need; we're not
        # checking for anything else.
        klass_methods = klass.methods - klass.instance_methods - Object.methods

        if MODULE_METHODS - klass_methods != []
          raise LoadError, "Driver module #{klass.name} is not implementing all "\
            "of the class methods #{MODULE_METHODS}, aborting!"
        end

        # The second question is whether the same class is already known, or
        # whether a class with the same name but under a different location is
        # known.
        if @@modules.include?(klass) and @@modules[klass] != fpath
          raise LoadError, "Driver module #{klass.name} is duplicated in file "\
            "'#{fpath}'; previous definition is here: "\
            "'#{@@modules[klass]}'"
        end

        # If all of that was ok, we can register the implementation.
        @@modules[klass] = fpath
      end

      private :new

      ##
      # @api private
      # Resolves everything to do with driver options:
      #
      # - Normalizes the label
      # - Loads the driver class
      # - Normalizes and extends options from the driver implementation
      #
      # @param label [Symbol, String] the driver label
      # @param opts [Hash] driver options
      def resolve_options(label, opts = nil)
        if label.nil? or label.empty?
          raise ArgumentError, "Need at least one argument specifying the driver!"
        end

        label = label.to_sym

        if not opts.nil?
          if not (opts.is_a? Hash or opts.is_a? ::Unobtainium::PathedHash)
            raise ArgumentError, "The second argument is expected to be an "\
              "options Hash!"
          end
        end

        # Get the driver class.
        load_drivers
        driver_klass = get_driver(label)
        if not driver_klass
          raise LoadError, "No driver implementation matching #{label} found, "\
            "aborting!"
        end

        # Sanitize options according to the driver's idea
        options = opts
        if driver_klass.respond_to?(:resolve_options)
          label, options = driver_klass.resolve_options(label, opts)
        end

        return label, options, driver_klass
      end

      ##
      # @api private
      # Load drivers; this loads all driver implementations included in this gem.
      # You can register external implementations with the :register_implementation
      # method.
      def load_drivers
        pattern = File.join(File.dirname(__FILE__), 'drivers', '*.rb')
        Dir.glob(pattern).each do |fpath|
          # Determine class name from file name
          fname = File.basename(fpath, '.rb')
          fname = fname.split('_').map(&:capitalize).join

          begin
            require fpath
            klassname = 'Unobtainium::Drivers::' + fname
            klass = Object.const_get(klassname)
            Driver.register_implementation(klass, fpath)
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
      # @api private
      # Out of the loaded drivers, returns the one matching the label (if any).
      # @param label [Symbol] The label matching a driver.
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
    end # class << self

    ############################################################################
    # Public methods

    # @return [Symbol] the normalized label for the driver implementation
    attr_reader :label

    # @return [Hash] the options hash the driver implementation is using.
    attr_reader :options

    # @return [Object] the driver implementation itself; do not use this unless
    #   you have to.
    attr_reader :impl

    ##
    # Map any missing method to the driver implementation
    def respond_to_missing?(meth, include_private = false)
      if not @impl.nil? and @impl.respond_to?(meth, include_private)
        return true
      end
      return super
    end

    ##
    # Map any missing method to the driver implementation
    def method_missing(meth, *args, &block)
      if not @impl.nil? and @impl.respond_to?(meth)
        return @impl.send(meth.to_s, *args, &block)
      end
      return super
    end

    private

    ##
    # Initializer
    def initialize(label, opts = nil)
      # Sanitize options
      @label, @options, driver_klass = ::Unobtainium::Driver.resolve_options(
          label,
          opts
      )

      # Perform precondition checks of the driver class
      driver_klass.ensure_preconditions(@label, @options)

      # Great, instanciate!
      @impl = driver_klass.create(@label, @options)

      # Now also extend this implementation with all the modues that match
      @@modules.each do |klass, _|
        if klass.matches?(@impl)
          @impl.extend(klass)
        end
      end
    end

    # Class variables have their place, rubocop... still, err on the strict
    # side and just skip this check here.
    # rubocop:disable Style/ClassVars
    @@drivers = {}
    @@modules = {}
    # rubocop:enable Style/ClassVars

    # Methods that drivers must implement
    DRIVER_METHODS = [
      :matches?,
      :ensure_preconditions,
      :create
    ].freeze

    # Methods that driver modules must implement
    MODULE_METHODS = [
      :matches?
    ].freeze
  end # class Driver
end # module Unobtainium
