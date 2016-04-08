
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

      ##
      # Add a new driver implementation. The first parameter is the class
      # itself, the second should be a file path pointing to the file where
      # the class is defined. You would typically pass __FILE__ for the second
      # parameter.
      #
      # Using file names lets us figure out whether the class is a duplicate,
      # or merely a second registration of the same class.
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

      private :new
    end # class << self

    ############################################################################
    # Public methods
    attr_reader :label, :options, :impl

    ##
    # Map any missing method to the driver implementation
    def respond_to?(meth)
      if not @impl.nil? and @impl.respond_to?(meth)
        return true
      end
      return super
    end

    def method_missing(meth, *args, &block)
      if not @impl.nil? and @impl.respond_to?(meth)
        return @impl.send(meth.to_s, *args, &block)
      end
      return super
    end

    private

    ##
    # Initializer
    def initialize(*args)
      # Load drivers
      load_drivers

      # Sanitize options
      @label, @options = sanitize_options(*args)

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
    # Ensures arguments are according to expectations.
    def sanitize_options(*args)
      if args.empty?
        raise ArgumentError, "Need at least one argument specifying the driver!"
      end

      label = args[0].to_sym

      options = nil
      if args.length > 1
        if not args[1].is_a? Hash
          raise ArgumentError, "The second argument is expected to be an options "\
            "hash!"
        end
        options = args[1]
      end

      return label, options
    end

    ##
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
