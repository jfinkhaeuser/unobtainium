require 'spec_helper'
require_relative '../lib/unobtainium/world'
require_relative './mock_driver.rb'

class Tester
  include ::Unobtainium::World
end # class Tester

describe ::Unobtainium::World do
  before :each do
    # Set configuration
    path = File.join(File.dirname(__FILE__), 'data', 'world.yml')
    ::Unobtainium::World.config_file = path

    # Load MockDriver
    ::Unobtainium::Driver.register_implementation(MockDriver, "mock_driver.rb")

    # Create tester object
    @tester = Tester.new
  end

  it "loads the global config" do
    expect(@tester.config["drivers.mock.option"]).to eql "value"
  end

  it "creates a mock driver parameters" do
    expect(@tester.driver.respond_to?(:passed_options)).to be_truthy
  end

  it "passed the config file options to the driver" do
    expect(@tester.driver.passed_options["option"]).to eql "value"
  end
end
