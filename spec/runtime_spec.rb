require 'spec_helper'
require_relative '../lib/unobtainium/runtime'

# rubocop:disable Style/ClassVars
class Foo
  @@instances = 0

  class << self
    def instances
      @@instances ||= 0
    end

    def instances=(value)
      @@instances = value
    end
  end

  def initialize
    Foo.instances += 1
  end

  def destroy
    Foo.instances -= 1
  end
end # class Foo
# rubocop:enable Style/ClassVars

describe ::Unobtainium::Runtime do
  it "is a singleton" do
    expect { ::Unobtainium::Runtime.new }.to raise_error(NoMethodError)
    first = ::Unobtainium::Runtime.instance
    second = ::Unobtainium::Runtime.instance
    expect(first).to eql second
  end

  it "can store objects" do
    ::Unobtainium::Runtime.instance.store("foo", 42)

    expect(::Unobtainium::Runtime.instance.has?("foo")).to be_truthy
    expect(::Unobtainium::Runtime.instance.length).to eql 1
    expect(::Unobtainium::Runtime.instance.fetch("foo")).to eql 42
    expect(::Unobtainium::Runtime.instance["foo"]).to eql 42
  end

  it "deals well with default values" do
    expect(::Unobtainium::Runtime.instance["bar"]).to be_nil
    expect { ::Unobtainium::Runtime.instance.fetch("bar") }.to raise_error(
        KeyError)
    expect(::Unobtainium::Runtime.instance.fetch("bar", 123)).to eql 123
  end

  it "destroys deleted objects" do
    expect(Foo.instances).to eql 0

    ::Unobtainium::Runtime.instance.store("foo", Foo.new)
    expect(Foo.instances).to eql 1

    ::Unobtainium::Runtime.instance.delete("foo")
    expect(Foo.instances).to eql 0
  end

  it "can use custom destructors" do
    called = false
    ::Unobtainium::Runtime.instance.store("foo", 666, proc { called = true })
    expect(called).to be_falsy

    ::Unobtainium::Runtime.instance.delete("foo")
    expect(called).to be_truthy
  end

  it "can store objects created from a block" do
    ::Unobtainium::Runtime.instance.store_with("foo") { 123 }
    expect(::Unobtainium::Runtime.instance.fetch("foo")).to eql 123
  end

  it "ignores nil objects created from a block" do
    ::Unobtainium::Runtime.instance.store_with("_nope_") { nil }
    expect { ::Unobtainium::Runtime.instance.fetch("_nope_") }.to raise_error(
        KeyError)
  end

  it "stores objects with :store_if" do
    ::Unobtainium::Runtime.instance.store_if("store_if", 42)
    expect(::Unobtainium::Runtime.instance.fetch("store_if")).to eql 42
  end

  it "does not overwrite objects with :store_if" do
    ::Unobtainium::Runtime.instance.store("foo", 42)
    ::Unobtainium::Runtime.instance.store_if("foo", 123)
    expect(::Unobtainium::Runtime.instance.fetch("foo")).to eql 42
  end

  it "stores objects with :store_with_if" do
    ::Unobtainium::Runtime.instance.store_with_if("store_with_if") do
      42
    end
    expect(::Unobtainium::Runtime.instance.fetch("store_with_if")).to eql 42
  end

  it "does not overwrite objects with :store_with_if" do
    ::Unobtainium::Runtime.instance.store("foo", 42)
    ::Unobtainium::Runtime.instance.store_with_if("foo") do
      123
    end
    expect(::Unobtainium::Runtime.instance.fetch("foo")).to eql 42
  end
end
