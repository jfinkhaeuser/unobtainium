# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#

require 'pathname'

require 'unobtainium/pathed_hash'

module Unobtainium
  ##
  # The Config class extends PathedHash by two main pieces of functionality:
  #
  # - it loads configuration files and turns them into pathed hashes, and
  # - it treats environment variables as overriding anything contained in
  #   the configuration file.
  #
  # For configuration file loading, a named configuration file will be laoaded
  # if present. A file with the same name but `-local` appended before the
  # extension will be loaded as well, overriding any values in the original
  # configuration file.
  #
  # For environment variable support, any environment variable named like a
  # path into the configuration hash, but with separators transformed to
  # underscore and all letters capitalized will override values from the
  # configuration files under that path, i.e. `FOO_BAR` will override `'foo.bar'`.
  #
  # Environment variables can contain JSON *only*; if the value can be parsed
  # as JSON, it becomes a Hash in the configuration tree. If it cannot be parsed
  # as JSON, it remains a string.
  #
  # **Note:** if your configuration file's top-level structure is an array, it
  # will be returned as a hash with a 'config' key that maps to your file's
  # contents.
  # That means that if you are trying to merge a hash with an array config, the
  # result may be unexpected.
  class Config < PathedHash
    # @api private
    # Very simple YAML parser
    class YAMLParser
      require 'yaml'

      # @return parsed string
      def self.parse(string)
        YAML.load(string)
      end
    end
    private_constant :YAMLParser

    # @api private
    # Very simple JSON parser
    class JSONParser
      require 'json'

      # @return parsed string
      def self.parse(string)
        JSON.parse(string)
      end
    end
    private_constant :JSONParser

    PathedHash::READ_METHODS.each do |method|
      # Wrap all read functions into something that checks for environment
      # variables first.
      define_method(method) do |*args, &block|
        # If there are no arguments, there's nothing to do with paths. Just
        # delegate to the hash.
        if args.empty?
          return super(*args, &block)
        end

        # We'll make it rather simple: since the first argument is a key, we
        # will just transform it to the matching environment variable name,
        # and see if that environment variable is set.
        env_name = args[0].to_s.upcase.gsub(split_pattern, '_')
        contents = nil
        if env_name != '_'
          contents = ENV[env_name]
        end

        # No environment variable set? Fine, just do the usual thing.
        if contents.nil? or contents.empty?
          return super(*args, &block)
        end

        # With an environment variable, we will try to parse it as JSON first.
        begin
          return JSONParser.parse(contents)
        rescue JSON::ParserError
          return contents
        end
      end
    end

    class << self
      # @api private
      # Mapping of file name extensions to parser types.
      FILE_TO_PARSER = {
        '.yml'  => YAMLParser,
        '.yaml' => YAMLParser,
        '.json' => JSONParser,
      }.freeze
      private_constant :FILE_TO_PARSER

      # @api private
      # If the config file contains an Array, this is what they key of the
      # returned Hash will be.
      ARRAY_KEY = 'config'.freeze
      private_constant :ARRAY_KEY

      ##
      # Loads a configuration file with the given file name. The format is
      # detected based on one of the extensions in FILE_TO_PARSER.
      #
      # @param path [String] the path of the configuration file to load.
      # @param resolve_extensions [Boolean] flag whether to resolve configuration
      #   hash extensions. (see `#resolve_extensions`)
      def load_config(path, resolve_extensions = true)
        # Load base and local configuration files
        base, config = load_base_config(path)
        _, local_config = load_local_config(base)

        # Merge local configuration
        config.recursive_merge!(local_config)

        # Resolve includes
        config = resolve_includes(base, config)

        # Create config from the result
        cfg = Config.new(config)

        # Now resolve config hashes that extend other hashes.
        if resolve_extensions
          cfg.resolve_extensions!
        end

        return cfg
      end

      private

      def load_base_config(path)
        # Make sure the format is recognized early on.
        base = Pathname.new(path)
        formats = FILE_TO_PARSER.keys
        if not formats.include?(base.extname)
          raise ArgumentError, "Files with extension '#{base.extname}' are not"\
                " recognized; please use one of #{formats}!"
        end

        # Don't check the path whether it exists - loading a nonexistent
        # file will throw a nice error for the user to catch.
        file = base.open
        contents = file.read

        # Parse the contents.
        config = FILE_TO_PARSER[base.extname].parse(contents)

        return base, PathedHash.new(hashify(config))
      end

      def load_local_config(base)
        # Now construct a file name for a local override.
        local = Pathname.new(base.dirname)
        local = local.join(base.basename(base.extname).to_s + "-local" +
            base.extname)
        if not local.exist?
          return local, nil
        end

        # We know the local override file exists, but we do want to let any errors
        # go through that come with reading or parsing it.
        file = local.open
        contents = file.read

        local_config = FILE_TO_PARSER[base.extname].parse(contents)

        return local, PathedHash.new(hashify(local_config))
      end

      def hashify(data)
        if data.nil?
          return {}
        end
        if data.is_a? Array
          data = { ARRAY_KEY => data }
        end
        return data
      end

      def resolve_includes(base, config)
        processed = []
        includes = []

        loop do
          # Figure out includes
          outer_inc = extract_includes(config)
          if not outer_inc.empty?
            includes = outer_inc
          end

          to_process = includes - processed

          # Stop resolving when all includes have been processed
          if to_process.empty?
            break
          end

          # Load and merge the include files
          to_process.each do |filename|
            incfile = Pathname.new(base.dirname)
            incfile = incfile.join(filename)

            # Just try to open it, if that errors out that's ok.
            file = incfile.open
            contents = file.read

            parsed = FILE_TO_PARSER[incfile.extname].parse(contents)

            # Extract and merge includes
            inner_inc = extract_includes(parsed)
            includes += inner_inc

            # Merge the rest
            config.recursive_merge!(PathedHash.new(hashify(parsed)))

            processed << filename
          end
        end

        return config
      end

      def extract_includes(config)
        # Figure out includes
        includes = config.fetch("include", [])
        config.delete("include")
        includes = config.fetch(:include, includes)
        config.delete(:include)

        # We might have a simple/string include
        if not includes.is_a? Array
          includes = [includes]
        end

        return includes
      end
    end # class << self

    ##
    # Resolve extensions in configuration hashes. If your hash contains e.g.:
    #
    # ```yaml
    #   foo:
    #     bar:
    #       some: value
    #     baz:
    #       extends: bar
    # ```
    #
    # Then `'foo.baz.some'` will equal `'value'` after resolving extensions. Note
    # that `:load_config` calls this function, so normally you don't need to call
    # it yourself. You can switch this behaviour off in `:load_config`.
    #
    # Note that this process has some intended side-effects:
    #
    # 1. If a hash can't be extended because the base cannot be found, an error
    #    is raised.
    # 1. If a hash got successfully extended, the `extends` keyword itself is
    #    removed from the hash.
    # 1. In a successfully extended hash, an `base` keyword, which contains
    #    the name of the base. In case of multiple recursive extensions, the
    #    final base is stored here.
    #
    # Also note that all of this means that :extends and :base are reserved
    # keywords that cannot be used in configuration files other than for this
    # purpose!
    def resolve_extensions!
      recursive_merge("", "")
    end

    ##
    # Same as `dup.resolve_extensions!`
    def resolve_extensions
      dup.resolve_extensions!
    end

    private

    def recursive_merge(parent, key)
      loop do
        full_key = "#{parent}#{separator}#{key}"

        # Recurse down to the remaining root of the hierarchy
        base = full_key
        derived = nil
        loop do
          new_base, new_derived = resolve_extension(parent, base)

          if new_derived.nil?
            break
          end

          base = new_base
          derived = new_derived
        end

        # If recursion found nothing to merge, we're done!
        if derived.nil?
          break
        end

        # Otherwise, merge what needs merging and continue
        merge_extension(base, derived)
      end
    end

    def resolve_extension(grandparent, parent)
      fetch(parent, {}).each do |key, value|
        # Recurse into hash values
        if value.is_a? Hash
          recursive_merge(parent, key)
        end

        # No hash, ignore any keys other than the special "extends" key
        if key != "extends"
          next
        end

        # If the key is "extends", return a normalized version of its value.
        full_value = value.dup
        if not full_value.start_with?(separator)
          full_value = "#{grandparent}#{separator}#{value}"
        end

        if full_value == parent
          next
        end
        return full_value, parent
      end

      return nil, nil
    end

    def merge_extension(base, derived)
      # Remove old 'extends' key, but remember the value
      extends = self[derived]["extends"]
      self[derived].delete("extends")

      # Recursively merge base into derived without overwriting
      self[derived].extend(::Unobtainium::RecursiveMerge)
      self[derived].recursive_merge!(self[base], false)

      # Then set the "base" keyword, but only if it's not yet set.
      if not self[derived]["base"].nil?
        return
      end
      self[derived]["base"] = extends
    end
  end # class Config
end # module Unobtainium
