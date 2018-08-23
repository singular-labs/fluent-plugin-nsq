require 'rspec'

describe Fluent::Plugin::NSQOutput do
  describe 'posting messages to nsq' do
    before do
      @nsqd = @cluster.nsqd.first
      @consumer = new_consumer(nsqlookupd: nil, nsqd: "#{@nsqd.host}:#{@nsqd.tcp_port}", max_in_flight: 10)
    end
    after do
      @consumer.terminate
    end

    it 'should successfully write messages to a topic' do

      true.should == false
    end
  end
end
