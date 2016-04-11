class Mock
  attr_accessor :passed_options

  def initialize(opts)
    @passed_options = opts
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
# rubocop:enable Style/GuardClause
