require 'spec_helper'
require_relative '../lib/unobtainium/driver'
require_relative './mock_driver.rb'

class FakeDriver
end # class FakeDriver

describe ::Unobtainium::Driver do
  before :each do
    ::Unobtainium::Driver.register_implementation(MockDriver, __FILE__)
  end

  it "refuses to register a driver with missing methods" do
    expect do
      ::Unobtainium::Driver.register_implementation(FakeDriver, __FILE__)
    end.to raise_error(LoadError)
  end

  it "refuses to register the same driver twice from different locations" do
    expect do
      ::Unobtainium::Driver.register_implementation(MockDriver, __FILE__ + "foo")
    end.to raise_error(LoadError)
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

  it "delegates to created driver class" do
    drv = ::Unobtainium::Driver.create(:mock, foo: 42)
    expect(drv.respond_to?(:passed_options)).to be_truthy
    _ = drv.passed_options
  end

  it "passes options through correctly" do
    drv = ::Unobtainium::Driver.create(:mock, foo: 42)
    expect(drv.passed_options).to eql foo: 42
  end
end
