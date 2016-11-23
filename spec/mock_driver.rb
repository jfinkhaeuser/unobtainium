class Mock
  attr_accessor :passed_options

  def initialize(opts)
    @passed_options = opts
  end

  def quit
  end
end

# rubocop:disable Style/GuardClause
class MockDriver
  class << self
    def matches?(label)
      label == :mock || label == :raise_mock
    end

    def ensure_preconditions(label, _)
      if label == :raise_mock
        raise "something"
      end
    end

    def create(_, options)
      Mock.new(options)
    end
  end
end # class MockDriver

class OptionResolvingMockDriver < MockDriver
  class << self
    def matches?(label)
      label == :option_resolving
    end

    def resolve_options(label, options)
      if options
        opts = options.dup
      end
      opts ||= {}

      if opts[:foo] == 123 or opts[:foo].nil?
        opts[:foo] = 42
      end

      opts["unobtainium_instance_id"] = 'FIXED'

      return label, opts
    end
  end
end # class OptionResolvingMockDriver
# rubocop:enable Style/GuardClause
