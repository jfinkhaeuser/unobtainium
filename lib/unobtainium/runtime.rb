# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#
require 'singleton'

module Unobtainium

  ##
  # The Runtime class is a singleton scoped to destroy itself when script
  # execution stops. It's also an object map, which will destroy all object
  # it contains when it destroys itself.
  #
  # Therefore, it can be used as a way to register object instances for
  # destruction at script end.
  class Runtime
    include Singleton

    ##
    # Initializer
    def initialize
      @objects = {}

      # Create our own finalizer
      ObjectSpace.define_finalizer(self) do
        @objects.keys.each do |key|
          unset(key)
        end
      end
    end

    ##
    # Number of objects stored in the object map
    def length
      return @objects.length
    end

    ##
    # Does an object with the given name exist?
    def has?(name)
      return @objects.key?(name)
    end

    ##
    # Store the given object under the given name. This overwrites any objects
    # already stored under that name, which are destroyed before the new object
    # is stored.
    #
    # If a destructor is passed, it is used to destroy the *new* object only.
    # If no destructor is passed and the object responds to a :destroy method, that
    # method is called.
    def set(name, object, destructor = nil)
      unset(name)

      @objects[name] = [object, destructor]

      return object
    end

    ##
    # Store the object returned by the block, if any. If no object is returned
    # or no block is given, this function does nothing.
    #
    # Otherwise it works much like :set above.
    def set_with(name, destructor = nil, &block)
      object = nil
      if not block.nil?
        object = yield
      end

      if object.nil?
        return
      end

      return set(name, object, destructor)
    end

    ##
    # Unsets (and destroys) any object found under the given name.
    def unset(name)
      if not @objects.key?(name)
        return
      end

      obj, dtor = @objects[name]
      @objects.delete(name)
      destroy(obj, dtor)
    end

    ##
    # Returns the object with the given name, or the default value if no such
    # object exists.
    def fetch(name, default = nil)
      return @objects.fetch(name, default)
    end

    ##
    # Similar to :fetch, but always returns nil for an object that could not
    # be found.
    def [](name)
      return @objects[name]
    end

    private

    ##
    # Destroy the given object with the destructor provided.
    def destroy(object, destructor)
      if not destructor.nil?
        destructor.call
        return
      end

      if not object.respond_to?(:destroy)
        return
      end

      object.send(:destroy)
    end
  end # class Runtime

end # module Unobtainium
