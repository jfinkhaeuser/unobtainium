require 'spec_helper'
require_relative '../lib/unobtainium/support/identifiers'

describe ::Unobtainium::Support::Identifiers do
  let(:tester) { Class.new { extend ::Unobtainium::Support::Identifiers } }

  it "creates IDs starting with the given scope" do
    expect(tester.identifier('noodle', 'foo')).to start_with 'noodle'
  end

  it "creates the same ID for identical input" do
    opts = { foo: 'bar', "baz" => 42 }
    first = tester.identifier('test', 'mylabel', opts.dup)
    second = tester.identifier('test', 'mylabel', opts.dup)
    expect(first).to eql second
  end

  context "different input" do
    it "creates different IDs for different scopes" do
      opts = { foo: 'bar', "baz" => 42 }
      first = tester.identifier('scope1', 'mylabel', opts.dup)
      second = tester.identifier('scope2', 'mylabel', opts.dup)
      expect(first).not_to eql second
    end

    it "creates different IDs for different labels" do
      opts = { foo: 'bar', "baz" => 42 }
      first = tester.identifier('test', 'label1', opts.dup)
      second = tester.identifier('test', 'label2', opts.dup)
      expect(first).not_to eql second
    end

    it "creates different IDs for different options" do
      opts1 = { foo: 'bar', "baz" => 42 }
      opts2 = opts1.dup
      opts2['baz'] = 123
      first = tester.identifier('test', 'mylabel', opts1)
      second = tester.identifier('test', 'mylabel', opts2)
      expect(first).not_to eql second
    end
  end
end
