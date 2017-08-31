require 'spec_helper'
require_relative '../lib/unobtainium/support/runner'

describe ::Unobtainium::Support::Runner do
  it "refuses to initialize without ID" do
    expect do
      ::Unobtainium::Support::Runner.new
    end.to raise_error(ArgumentError)
  end

  it "refuses to initialize without command" do
    expect do
      ::Unobtainium::Support::Runner.new("foo")
    end.to raise_error(ArgumentError)
  end

  it "runs a shell command" do
    runner = ::Unobtainium::Support::Runner.new("foo", %w[ls -l])
    expect(runner.pid).to be_nil
    runner.start
    expect(runner.pid).not_to be_nil
    expect(runner.pid).to be > 0
    runner.wait
    expect(runner.pid).to be_nil
  end

  it "captures output" do
    runner = ::Unobtainium::Support::Runner.new("foo", %w[ls -l])
    runner.start
    runner.wait
    expect(runner.stdout).not_to be_nil
    expect(runner.stderr).not_to be_nil

    # Read stdout
    out = runner.stdout.read
    expect(out).not_to be_empty
  end

  it "can be killed" do
    runner = ::Unobtainium::Support::Runner.new("foo", %w[sleep 30])
    runner.start
    expect(runner.pid).not_to be_nil
    runner.kill
    expect(runner.pid).to be_nil
  end

  it "verifies #signal arguments" do
    runner = ::Unobtainium::Support::Runner.new("foo", %w[sleep 30])
    expect { runner.signal("KILL", scope: :foo) }.to raise_error(RuntimeError)
    runner.start
    expect { runner.signal("KILL", scope: :foo) }.to raise_error(ArgumentError)
    runner.signal("KILL", scope: :self)
  end

  it "errors for invalid commands" do
    runner = ::Unobtainium::Support::Runner.new("foo", "no_shell_command")
    expect { runner.start }.to raise_error(Errno::ENOENT)
  end

  it "refuses to run the command twice without ending it first" do
    runner = ::Unobtainium::Support::Runner.new("foo", %w[ls -l])
    expect { runner.start }.not_to raise_error
    expect { runner.start }.to raise_error(RuntimeError)
    runner.wait
  end

  it "kills when destroyed" do
    runner = ::Unobtainium::Support::Runner.new("foo", %w[sleep 30])
    runner.start
    expect(runner.pid).not_to be_nil
    runner.destroy
    expect(runner.pid).to be_nil
  end

  it "cannot be killed twice" do
    runner = ::Unobtainium::Support::Runner.new("foo", %w[sleep 30])
    runner.start
    expect(runner.pid).not_to be_nil
    runner.kill

    expect do
      runner.kill
    end.to raise_error(RuntimeError)
  end
end
