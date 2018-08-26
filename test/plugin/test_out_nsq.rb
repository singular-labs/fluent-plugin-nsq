require 'fluent/test'
require 'fluent/test/driver/output'
require 'fluent/test/helpers'
require 'fluent/plugin/out_nsq'

class TestNSQOutput < Test::Unit::TestCase
  BASE_CONFIG = %[
    nsqd localhost:4151
    topic test
  ]

  include Fluent::Test::Helpers

  setup do
    Fluent::Test.setup
  end

  def create_driver(conf = {})
    Fluent::Test::Driver::Output.new(Fluent::Plugin::NSQOutput).configure(conf)
  end

  test 'emit' do
    d = create_driver(config = BASE_CONFIG)
    es = Fluent::OneEventStream.new(event_time, { "message" => "Hello, Fluentd!!" })
    d.run do
      d.feed("test", es)
    end
  end

  def assert_received_by_nsq(nsqd_host, topic, messages)

  end
end