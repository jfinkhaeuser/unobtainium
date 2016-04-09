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
  # a) it loads configuration files and turns them into pathed hashes, and
  # b) it treats environment variables as overriding anything contained in
  #    the configuration file.
  #
  # For configuration file loading, a named configuration file will be laoaded
  # if present. A file with the same name but '-local' appended before the
  # extension will be loaded as well, overriding any values in the original
  # configuration file.
  #
  # For environment variable support, any environment variable named like a
  # path into the configuration hash, but with separators transformed to
  # underscore and all letters capitalized will override values from the
  # configuration files under that path, i.e. FOO_BAR will override 'foo.bar'.
  #
  # Environment variables can contain JSON *only*; if the value can be parsed
  # as JSON, it becomes a Hash in the configuration tree. If it cannot be parsed
  # as JSON, it remains a string.
  #
  # Note: if your configuration file's top-level structure is an array, it will
  # be returned as a hash with a 'config' key that maps to your file's contents.
  # That means that if you are trying to merge a hash with an array config, the
  # result may be unexpected.
  class Config < PathedHash
    # Very simple YAML parser
    class YAMLParser
      require 'yaml'

      def self.parse(string)
        YAML.load(string)
      end
    end

    # Very simple JSON parser
    class JSONParser
      require 'json'

      def self.parse(string)
        JSON.parse(string)
      end
    end

    PathedHash::READ_METHODS.each do |method|
      # Wrap all read functions into something that checks for environment
      # variables first.
      define_method(method) do |*args, &block|
        # We'll make it rather simple: since the first argument is a key, we
        # will just transform it to the matching environment variable name,
        # and see if that environment variable is set.
        env_name = args[0].upcase.gsub(split_pattern, '_')
        contents = ENV[env_name]

        # No environment variable set? Fine, just do the usual thing.
        if contents.nil?
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
      # Mapping of file name extensions to parser types.
      FILE_TO_PARSER = {
        '.yml'  => YAMLParser,
        '.yaml' => YAMLParser,
        '.json' => JSONParser,
      }.freeze

      # If the config file contains an Array, this is what they key of the
      # returned Hash will be.
      ARRAY_KEY = 'config'.freeze

      ##
      # Loads a configuration file with the given file name. The format is
      # detected based on one of the extensions in FILE_TO_PARSER.
      def load_config(path)
        # Load base and local configuration files
        base, config = load_base_config(path)
        _, local_config = load_local_config(base)
        if local_config.nil?
          return Config.new(config)
        end

        # Merge
        merger = proc do |_, v1, v2|
          # rubocop:disable Style/GuardClause
          if v1.is_a? Hash and v2.is_a? Hash
            next v1.merge(v2, &merger)
          elsif v1.is_a? Array and v2.is_a? Array
            next v1 + v2
          end
          next v2
          # rubocop:enable Style/GuardClause
        end
        config.merge!(local_config, &merger)

        return Config.new(config)
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

        return base, hashify(config)
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

        return local, hashify(local_config)
      end

      def hashify(data)
        if data.is_a? Array
          data = { ARRAY_KEY => data }
        end
        return data
      end
    end # class << self
  end # class Config
end # module Unobtainium
