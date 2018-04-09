require 'spec_helper'
require_relative '../lib/unobtainium/support/port_scanner'

describe ::Unobtainium::Support::PortScanner do
  let(:tester) { Class.new { extend ::Unobtainium::Support::PortScanner } }

  # This Socket#connect mock finds port 1234 or 4321 open
  def connect_mock(_, addr)
    port, = Socket.unpack_sockaddr_in(addr)
    if [1234, 4321].include?(port)
      raise Errno::EISCONN
    end
    raise Errno::ECONNREFUSED
  end

  describe "port_open?" do
    it "detects an open port correctly" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock).and_raise(
          Errno::EISCONN
      )
      expect(tester.port_open?('localhost', 1234)).to be_truthy
    end

    it "detects a closed port correctly" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock).and_raise(
          Errno::ECONNREFUSED
      )
      expect(tester.port_open?('localhost', 1234)).to be_falsy
    end

    it "handles a single domain parameter" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock).and_raise(
          Errno::ECONNREFUSED
      )
      expect(tester.port_open?('localhost', 1234, :INET)).to be_falsy
    end

    it "handles many domain parameters" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock).and_raise(
          Errno::ECONNREFUSED
      )
      expect(tester.port_open?('localhost', 1234, %i[INET INET6])).to be_falsy
    end

    it "rejects bad domain parameters" do
      expect do
        tester.port_open?('localhost', 1234, :FOO)
      end.to raise_error(ArgumentError)
    end

    it "handles unsupported protocols gracefully" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock).and_raise(
          Errno::EINVAL # or EAFNOSUPPORT
      )
      expect(tester.port_open?('localhost', 1234, %i[INET INET6])).to be_falsy
    end

    it "handles unavailable addresses" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock).and_raise(
          Errno::EADDRNOTAVAIL
      )
      expect(tester.port_open?('localhost', 1234, %i[INET INET6])).to be_falsy
    end

    it "retries for several seconds if a socket is being created" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock).and_raise(
          Errno::EINPROGRESS
      )
      before = Time.now.utc
      expect(tester.port_open?('localhost', 1234, %i[INET INET6])).to be_falsy
      after = Time.now.utc

      elapsed = after - before
      expected_max_time = ::Unobtainium::Support::PortScanner::MAX_RETRIES \
                          * ::Unobtainium::Support::PortScanner::RETRY_DELAY
      expect(elapsed).to be <= expected_max_time
    end
  end

  describe "scan" do
    it "aborts on bad parameters" do
      expect { tester.scan }.to raise_error(ArgumentError)
      expect { tester.scan('localhost') }.to raise_error(ArgumentError)
      expect { tester.scan('localhost', "foo") }.to raise_error(ArgumentError)
      expect { tester.scan('localhost', :sym) }.to raise_error(ArgumentError)
    end

    it "finds an open port in a range" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock) do |sock, addr|
        connect_mock(sock, addr)
      end

      expect(tester.scan('localhost', 1230..1240)).to eql [1234]
    end

    it "finds an open port in an array" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock) do |sock, addr|
        connect_mock(sock, addr)
      end

      expect(tester.scan('localhost', [1233, 1234, 1235])).to eql [1234]
    end

    it "doesn't find an open port in a range" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock) do |sock, addr|
        connect_mock(sock, addr)
      end

      expect(tester.scan('localhost', 1240..1250)).to eql []
    end

    it "doesn't find an open port in an array" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock) do |sock, addr|
        connect_mock(sock, addr)
      end

      expect(tester.scan('localhost', [1230, 1231])).to eql []
    end

    it "finds an open port in mixed arguments" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock) do |sock, addr|
        connect_mock(sock, addr)
      end

      # Match in first argument
      expect(tester.scan('localhost', 1234, [1, 2], 3..4)).to eql [1234]
      expect(tester.scan('localhost', 1230..1240, 3, [1, 2])).to eql [1234]
      expect(tester.scan('localhost', [1, 1234], 3..4, 5)).to eql [1234]

      # Match in second argument
      expect(tester.scan('localhost', 1, [1, 1234], 3..4)).to eql [1234]
      expect(tester.scan('localhost', 1..2, 1234, [1, 2])).to eql [1234]
      expect(tester.scan('localhost', [1, 2], 1230..1240, 5)).to eql [1234]
    end

    it "can abort after the first find" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock) do |sock, addr|
        connect_mock(sock, addr)
      end

      expect(tester.scan('localhost', 1230..4330, amount: :first)).to eql [1234]
    end

    it "can return successfully after the first find" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock) do |sock, addr|
        connect_mock(sock, addr)
      end

      expect(tester.scan('localhost', 1230..4330, amount: :first)).to eql [1234]
    end

    it "can scan for closed/available ports" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock) do |sock, addr|
        connect_mock(sock, addr)
      end

      expect(tester.scan('localhost', 1233..1234, for: :closed)).to eql [1233]
    end

    it "can scan for the first closed/available port" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock) do |sock, addr|
        connect_mock(sock, addr)
      end

      opts = {
        amount: :first,
        for: :closed,
      }
      expect(tester.scan('localhost', 1232..1234, opts)).to eql [1232]
    end

    it "can scan for the first string port" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock) do |sock, addr|
        connect_mock(sock, addr)
      end

      expect(tester.scan('localhost', '1234', amount: :first)).to eql [1234]
    end

    it "rejects bad amounts" do
      expect do
        tester.scan('localhost', 1230..4330, amount: :foo)
      end.to raise_error(ArgumentError)
    end

    it "rejects bad for" do
      expect do
        tester.scan('localhost', 1230..4330, for: :foo)
      end.to raise_error(ArgumentError)
    end
  end
end
