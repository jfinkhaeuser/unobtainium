require 'spec_helper'
require_relative '../lib/unobtainium/pathed_hash'

describe ::Unobtainium::PathedHash do
  describe "#initialize" do
    it "can be constructed without values" do
      ph = ::Unobtainium::PathedHash.new
      expect(ph.empty?).to eql true
    end

    it "can be constructed with values" do
      ph = ::Unobtainium::PathedHash.new(foo: 42)
      expect(ph.empty?).to eql false
      expect(ph[:foo]).to eql 42
    end

    it "can be constructed with a nil value" do
      ph = ::Unobtainium::PathedHash.new(nil)
      expect(ph.empty?).to eql true
    end
  end

  describe "Hash-like" do
    it "responds to Hash functions" do
      ph = ::Unobtainium::PathedHash.new
      [:invert, :delete, :fetch].each do |meth|
        expect(ph.respond_to?(meth)).to eql true
      end
    end

    it "can be used like a hash" do
      ph = ::Unobtainium::PathedHash.new(foo: 42)
      inverted = ph.invert
      expect(inverted.empty?).to eql false
      expect(inverted[42]).to eql :foo
    end
  end

  it "can recursively read entries via a path" do
    sample = {
      "foo" => 42,
      "bar" => {
        "baz" => "quux",
        "blah" => [1, 2],
      }
    }
    ph = ::Unobtainium::PathedHash.new(sample)

    expect(ph["foo"]).to eql 42
    expect(ph["bar.baz"]).to eql "quux"
    expect(ph["bar.blah"]).to eql [1, 2]

    expect(ph["nope"]).to eql nil
    expect(ph["bar.nope"]).to eql nil
  end

  it "can be used with indifferent access from string key" do
    sample = {
      "foo" => 42,
    }
    ph = ::Unobtainium::PathedHash.new(sample)

    expect(ph["foo"]).to eql 42
    expect(ph[:foo]).to eql 42
  end

  it "can be used with indifferent access from symbol key" do
    sample = {
      foo: 42,
      bar: {
        baz: 'quux',
      }
    }
    ph = ::Unobtainium::PathedHash.new(sample)

    expect(ph["foo"]).to eql 42
    expect(ph[:foo]).to eql 42

    expect(ph['bar.baz']).to eql 'quux'
  end

  it "treats a single separator as the root" do
    sample = { "foo" => 42 }
    ph = ::Unobtainium::PathedHash.new(sample)

    expect(ph[ph.separator]["foo"]).to eql 42
  end

  it "treats an empty path as the root" do
    sample = { "foo" => 42 }
    ph = ::Unobtainium::PathedHash.new(sample)

    expect(ph[""]["foo"]).to eql 42
  end

  it "can recursively write entries via a path" do
    ph = ::Unobtainium::PathedHash.new
    ph["foo.bar"] = 42
    expect(ph["foo.bar"]).to eql 42
  end

  it "has the same string representation as the hash it's initialized from" do
    h = { foo: 42 }
    ph = ::Unobtainium::PathedHash.new(h)
    expect(ph.to_s).to eql h.to_s
  end

  it "understands absolute paths (starting with separator)" do
    sample = {
      "foo" => 42,
      "bar" => {
        "baz" => "quux",
        "blah" => [1, 2],
      }
    }
    ph = ::Unobtainium::PathedHash.new(sample)

    expect(ph["bar.baz"]).to eql "quux"
    expect(ph[".bar.baz"]).to eql "quux"
  end

  it "recursively merges with overwriting" do
    sample1 = {
      "foo" => {
        "bar" => 42,
        "baz" => "quux",
      }
    }
    sample2 = {
      "foo" => {
        "baz" => "override"
      }
    }

    ph1 = ::Unobtainium::PathedHash.new(sample1)
    ph2 = ph1.recursive_merge(sample2)

    expect(ph2["foo.bar"]).to eql 42
    expect(ph2["foo.baz"]).to eql "override"
  end

  it "recursively merges without overwriting" do
    sample1 = {
      "foo" => {
        "bar" => 42,
        "baz" => "quux",
      }
    }
    sample2 = {
      "foo" => {
        "baz" => "override"
      }
    }

    ph1 = ::Unobtainium::PathedHash.new(sample1)
    ph2 = ph1.recursive_merge(sample2, false)

    expect(ph2["foo.bar"]).to eql 42
    expect(ph2["foo.baz"]).to eql "quux"
  end
end
