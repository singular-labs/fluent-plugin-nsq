require 'fluent/test'
require 'fluent/test/driver/output'
require 'fluent/test/helpers'
require 'fluent/plugin/out_nsq'
require 'securerandom'
require 'json'

class TestNSQOutput < Test::Unit::TestCase

  LOGS_DIR = '/tmp/fluent-plugin-nsq-tests'

  include Fluent::Test::Helpers

  setup do
    Fluent::Test.setup
    ensure_test_env
  end

  def ensure_test_env
    # TODO: execute docker-compose up
  end

  def create_config_for_topic(topic_name)
    %[
    nsqd localhost:4151
    topic #{topic_name}
    ]
  end

  def get_random_test_id
    'test_' + SecureRandom.hex[0, 10]
  end

  def create_driver(conf = {})
    Fluent::Test::Driver::Output.new(Fluent::Plugin::NSQOutput).configure(conf)
  end

  def send_messages(driver, messages, tag='test')
    messages_records = messages.map{|message| [event_time, { "message" => message }]}
    es = Fluent::ArrayEventStream.new(messages_records)
    driver.run do
      driver.feed(tag, es)
    end
  end

  def assert_received_by_nsq(test_id, messages)
    wait_for_queue_to_clean test_id
    log_file_loc = "#{LOGS_DIR}/#{test_id}.log"
    assert_equal(true, File.file?(log_file_loc), "log file doesn't exists for test_id: #{log_file_loc}")
    assert_all_messages_in_file(messages, log_file_loc)
  end

  def assert_all_messages_in_file(messages, log_file_loc)
    messages_from_file = extract_messages_from_file log_file_loc
    assert_equal(messages_from_file.length, messages.length, "Messages count in log file is different that expected: expected: #{messages.length} actual:#{messages_from_file.length}, file: #{log_file_loc}")
    messages_xor = messages + messages_from_file - (messages & messages_from_file)
    assert_equal(0, messages_xor.length, "Messages in log file are different than expected ones: expected: #{messages}, actual: (in file: #{log_file_loc}) #{messages_from_file}")
  end

  def extract_messages_from_file(file_location)
    messages = Set.new
    File.open(file_location) do |file|
      file.each do |line|
        parsed_line = JSON.parse(line)
        message = parsed_line["message"]
        assert_not_nil(message, "field 'message' does not exists in line [log file: #{file_location}]")
        assert_not_nil(messages.add?(message), "duplicated message in file #{file_location}")
      end
    end
    messages
  end

  def wait_for_queue_to_clean(topic)
    sleep(5)
  end

  test 'send messages to nsq' do
    test_id = get_random_test_id
    d = create_driver(config = create_config_for_topic(test_id))

    messages = Set['message1' ,'message2' ,'message3']
    send_messages(d, messages)

    assert_received_by_nsq(test_id, messages)
  end

  test 'send messages - too long topic name' do

    d = create_driver(config = create_config_for_topic("a" * 65))
    messages = Set['message1' ,'message2' ,'message3']
    send_messages(d, messages)

  end

end