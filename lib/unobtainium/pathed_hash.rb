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
  # The PathedHash class wraps Hash by offering pathed access on top of
  # regular access, i.e. instead of h["first"]["second"] you can write
  # h["first.second"]
  class PathedHash
    ##
    # Initializer
    def initialize(init = {})
      @data = init
      @separator = '.'
    end

    # The separator is the character or pattern splitting paths
    attr_accessor :separator

    READ_METHODS = [
      :[], :default, :delete, :fetch, :has_key?, :include?, :key?, :member?,
    ].freeze
    WRITE_METHODS = [
      :[]=, :store,
    ].freeze

    ##
    # Returns the pattern to split paths at
    def split_pattern
      /(?<!\\)#{Regexp.escape(@separator)}/
    end

    (READ_METHODS + WRITE_METHODS).each do |method|
      # Wrap all accessor functions to deal with paths
      define_method(method) do |*args, &block|
        # With any of the dispatch methods, we know that the first argument has
        # to be a key. We'll try to split it by the path separator.
        components = args[0].to_s.split(split_pattern)
        loop do
          if not components[0].empty?
            break
          end
          components.shift
        end

        # This PathedHash is already the leaf-most Hash
        if components.length == 1
          return @data.send(method, *args, &block)
        end

        # Deal with other paths. The frustrating part here is that for nested
        # hashes, only this outermost one is guaranteed to know anything about
        # path splitting, so we'll have to recurse down to the leaf here.
        #
        # For write methods, we need to create intermediary hashes.
        leaf = recursive_fetch(components, @data,
                               create: WRITE_METHODS.include?(method))

        # If the leaf is nil, we can't send it any method without raising
        # an error. We'll instead send the method to an empty hash, to mimic
        # the correct behaviour.
        if leaf.nil?
          return {}.send(method, *args, &block)
        end

        # If we have a leaf, we want to send the requested method to that
        # leaf.
        copy = args.dup
        copy[0] = components.last
        return leaf.send(method, *copy, &block)
      end
    end

    def to_s
      @data.to_s
    end

    ##
    # Map any missing method to the driver implementation
    def respond_to?(meth)
      if not @data.nil? and @data.respond_to?(meth)
        return true
      end
      return super
    end

    def method_missing(meth, *args, &block)
      if not @data.nil? and @data.respond_to?(meth)
        return @data.send(meth.to_s, *args, &block)
      end
      return super
    end

    private

    ##
    # Given the path components, recursively fetch any but the last key.
    def recursive_fetch(path, data, options = {})
      # For the leaf element, we do nothing because that's where we want to
      # dispatch to.
      if path.length == 1
        return data
      end

      # Split path into head and tail; for the next iteration, we'll look use only
      # head, and pass tail on recursively.
      head = path[0]
      tail = path.slice(1, path.length)

      # If we're a write function, then we need to create intermediary objects,
      # i.e. what's at head if nothing is there.
      if options[:create] and data.fetch(head, nil).nil?
        data[head] = {}
      end

      # Ok, recurse.
      return recursive_fetch(tail, data[head], options)
    end
  end # class PathedHash
end # module Unobtainium
