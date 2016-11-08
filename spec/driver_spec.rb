require 'spec_helper'
require_relative '../lib/unobtainium/driver'
require_relative './mock_driver.rb'

class FakeDriver
end # class FakeDriver

module TestModule
  class << self
    def matches?(_)
      # Always match!
      true
    end
  end # class << self

  def my_module_func
  end
end # module TestModule

module NonMatchingTestModule
  class << self
    def matches?(_)
      # Never match!
      false
    end
  end # class << self

  def does_not_exist
  end
end # module NonMatchingTestModule

module FakeModule
end # module FakeModule

describe ::Unobtainium::Driver do
  before :each do
    ::Unobtainium::Driver.register_implementation(MockDriver, "mock_driver.rb")
    ::Unobtainium::Driver.register_implementation(OptionResolvingMockDriver, "mock_driver.rb")
  end

  describe "driver registration" do
    it "refuses to register a driver with missing methods" do
      expect do
        ::Unobtainium::Driver.register_implementation(FakeDriver, __FILE__)
      end.to raise_error(LoadError)
    end

    it "refuses to register the same driver twice from different locations" do
      expect do
        ::Unobtainium::Driver.register_implementation(MockDriver, __FILE__ + '1')
        ::Unobtainium::Driver.register_implementation(MockDriver, __FILE__ + '2')
      end.to raise_error(LoadError)
    end
  end

  it "verifies arguments" do
    expect { ::Unobtainium::Driver.create }.to raise_error(ArgumentError)

    expect do
      ::Unobtainium::Driver.create(:mock, 1)
    end.to raise_error(ArgumentError)

    expect do
      ::Unobtainium::Driver.create(:mock, [])
    end.to raise_error(ArgumentError)

    expect do
      ::Unobtainium::Driver.create(:mock, "foo")
    end.to raise_error(ArgumentError)
  end

  describe "driver creation" do
    it "creates no driver with an unknown label" do
      expect { ::Unobtainium::Driver.create(:nope) }.to raise_error(LoadError)
    end

    it "fails preconditions correctly" do
      expect do
        ::Unobtainium::Driver.create(:raise_mock)
      end.to raise_error(RuntimeError)
    end

    it "creates a driver correctly" do
      ::Unobtainium::Driver.create(:mock)
    end

    it "does not create a driver with a nil label" do
      expect do
        ::Unobtainium::Driver.create(nil)
      end.to raise_error(ArgumentError)
    end
  end

  describe "driver behaviour" do
    it "delegates to created driver class" do
      drv = ::Unobtainium::Driver.create(:mock, foo: 42)
      expect(drv.respond_to?(:passed_options)).to be_truthy
      _ = drv.passed_options
    end

    it "passes options through correctly" do
      drv = ::Unobtainium::Driver.create(:mock, foo: 42)
      expect(drv.passed_options).to eql foo: 42
    end

    context "option resolution" do
      it "provides defaults" do
        drv = ::Unobtainium::Driver.create(:option_resolving)
        expect(drv.options).to include(:foo)
        expect(drv.options[:foo]).to eql 42
      end

      it "overrides when appropriate" do
        drv = ::Unobtainium::Driver.create(:option_resolving, foo: 123)
        expect(drv.options).to include(:foo)
        expect(drv.options[:foo]).to eql 42
      end

      it "does not override always" do
        drv = ::Unobtainium::Driver.create(:option_resolving, foo: 456)
        expect(drv.options).to include(:foo)
        expect(drv.options[:foo]).to eql 456
      end

      it "sets an instance ID" do
        drv = ::Unobtainium::Driver.create(:option_resolving)
        expect(drv.options).to include('unobtainium_instance_id')
        expect(drv.options['unobtainium_instance_id']).to eql 'FIXED'
      end
    end
  end

  describe 'modules' do
    it 'will register a module' do
      expect do
        ::Unobtainium::Driver.register_module(TestModule, __FILE__)
      end.not_to raise_error
    end

    it 'refuses to register the same module twice' do
      expect do
        ::Unobtainium::Driver.register_module(TestModule, __FILE__ + '1')
        ::Unobtainium::Driver.register_module(TestModule, __FILE__ + '2')
      end.to raise_error(LoadError)
    end

    it 'refuses to register a module with the wrong interface' do
      expect do
        ::Unobtainium::Driver.register_module(FakeModule, __FILE__)
      end.to raise_error(LoadError)
    end

    it 'extends a driver with a registered module' do
      expect do
        ::Unobtainium::Driver.register_module(TestModule, __FILE__)
      end.not_to raise_error

      drv = ::Unobtainium::Driver.create(:mock)

      expect(drv.respond_to?(:my_module_func)).to be_truthy
    end

    it 'does not extend a driver with a non-matching module' do
      expect do
        ::Unobtainium::Driver.register_module(TestModule, __FILE__)
        ::Unobtainium::Driver.register_module(NonMatchingTestModule, __FILE__)
      end.not_to raise_error

      drv = ::Unobtainium::Driver.create(:mock)

      expect(drv.respond_to?(:does_not_exist)).to be_falsy
    end
  end
end
