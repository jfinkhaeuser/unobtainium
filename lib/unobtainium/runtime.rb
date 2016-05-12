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
        # :nocov:
        @objects.keys.each do |key|
          delete(key)
        end
        # :nocov:
      end
    end

    ##
    # @return [Integer] number of objects stored in the object map
    def length
      return @objects.length
    end

    ##
    # @param name [String, Symbol] name or label for an object
    # @return [Boolean] does an object with the given name exist?
    def has?(name)
      return @objects.key?(name)
    end

    ##
    # Store the given object under the given name. This overwrites any objects
    # already stored under that name, which are destroyed before the new object
    # is stored.
    #
    # If a destructor is passed, it is used to destroy the *new* object only.
    # If no destructor is passed and the object responds to a `#destroy` method,
    # that method is called.
    #
    # @param name [String, Symbol] name or label for the object to store
    # @param object [Object] the object to store
    # @param destructor [Func] a custom destructor accepting the object as its
    #   parameter.
    # @return [Object] the stored object
    def store(name, object, destructor = nil)
      delete(name)

      @objects[name] = [object, destructor]

      return object
    end

    ##
    # Store the object returned by the block, if any. If no object is returned
    # or no block is given, this function does nothing.
    #
    # Otherwise it works much like `#store`.
    #
    # @param name [String, Symbol] name or label for the object to store
    # @param destructor [Func] a custom destructor accepting the object as its
    #   parameter.
    # @param block [Func] a block returning the created object.
    # @return [Object] the stored object
    def store_with(name, destructor = nil, &block)
      object = nil
      if not block.nil?
        object = yield
      end

      if object.nil?
        return
      end

      return store(name, object, destructor)
    end

    ##
    # (see #store)
    # Like `#store`, but only stores the object if none exists for that key yet.
    def store_if(name, object, destructor = nil)
      if has?(name)
        return self[name]
      end
      return store(name, object, destructor)
    end

    ##
    # (see #store_with)
    # Like `#store_if`, but as a block version similar to `#store_with`.
    def store_with_if(name, destructor = nil, &block)
      if has?(name)
        return self[name]
      end
      return store_with(name, destructor, &block)
    end

    ##
    # Deletes (and destroys) any object found under the given name.
    #
    # @param name [String, Symbol] name or label for the object to store
    def delete(name)
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
    #
    # @param name [String, Symbol] name or label for the object to retrieve
    # @param default [Object] default value to return if no object is found for
    #   name or label.
    # @return [Object] the object matching the name/label, or the default value.
    def fetch(name, default = nil)
      return @objects.fetch(name)[0]
    rescue KeyError
      if default.nil?
        raise
      end
      return default
    end

    ##
    # Similar to `#fetch`, but always returns nil for an object that could not
    # be found.
    #
    # @param name [String, Symbol] name or label for the object to retrieve
    # @return [Object] the object matching the name/label, or the default value.
    def [](name)
      val = @objects[name]
      if val.nil?
        return nil
      end
      return val[0]
    end

    private

    ##
    # Destroy the given object with the destructor provided.
    def destroy(object, destructor)
      if not destructor.nil?
        return destructor.call(object)
      end

      if not object.respond_to?(:destroy)
        return
      end

      object.send(:destroy)
    end
  end # class Runtime

end # module Unobtainium
