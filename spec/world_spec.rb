require 'spec_helper'
require_relative '../lib/unobtainium/world'
require_relative './mock_driver.rb'

class Tester
  include ::Unobtainium::World
end # class Tester

describe ::Unobtainium::World do
  before :each do
    # Set configuration
    path = File.join(File.dirname(__FILE__), 'data', 'driverconfig.yml')
    ::Unobtainium::World.config_file = path

    # Load MockDriver
    ::Unobtainium::Driver.register_implementation(MockDriver, "mock_driver.rb")

    # Create tester object
    @tester = Tester.new
  end

  it "has set the config file as expected" do
    expect(::Unobtainium::World.config_file).to end_with \
      File.join('data', 'driverconfig.yml')
  end

  it "loads the global config" do
    expect(@tester.config["drivers.mock.mockoption"]).to eql 42
  end

  it "creates a mock driver parameters" do
    expect(@tester.driver.respond_to?(:passed_options)).to be_truthy
  end

  it "passed the config file options to the driver" do
    expect(@tester.driver.passed_options["mockoption"]).to eql 42
  end

  it "extends driver options, but doesn't pass 'base' on" do
    expect(@tester.config["drivers.leaf.base"]).to eql %w[.global
                                                          .drivers.mock
                                                          .drivers.branch1
                                                          .drivers.branch2]
    expect(@tester.driver.passed_options["base"]).to be_nil
  end

  context "object identity" do
    context "#driver" do
      it "returns the same object for the same config" do
        first = @tester.driver.object_id
        second = @tester.driver.object_id
        expect(first).to eql second
      end

      it "returns a different object for different config" do
        first = @tester.driver(:mock, foo: true).object_id
        second = @tester.driver(:mock, foo: false).object_id
        expect(first).not_to eql second
      end
    end

    context "driver.impl" do
      it "returns the same object for the same config" do
        first = @tester.driver.impl.object_id
        second = @tester.driver.impl.object_id
        expect(first).to eql second
      end

      it "returns a different object for different config" do
        first = @tester.driver(:mock, foo: true).impl.object_id
        second = @tester.driver(:mock, foo: false).impl.object_id
        expect(first).not_to eql second
      end
    end
  end
end
