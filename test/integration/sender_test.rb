require 'test_helper'

class IntegrationSender < SenderService
  class_attribute :calls
  self.calls = []

  def send_paras _chat_id, paras
    self.class.calls << paras.first
    sleep 0.05
    SymMash.new id: self.class.calls.length, text: paras.first
  end
end

class SenderIntegrationTest < Minitest::Test
  SERVICE = 'integration'

  def setup
    @chat_id = "sender-test-#{Process.pid}-#{object_id}"
    @content = %w[before next after last].map do |name|
      {final: [name + ('-' + ('x' * 300))]}
    end

    Subscriber.db[:subscribers].insert(
      service:   SERVICE,
      chat_id:   @chat_id,
      name:      'sender test',
      parser:    'BaseParser',
      opts:      '{}',
      enabled:   false,
      content:   JSON.generate(@content),
      last_sent: JSON.generate(index: 0, size: 1, text: @content.first[:final]),
      messages:  '[]',
    )

    IntegrationSender.calls = []
    IntegrationSender.running = false
    Sender.subscribers = {}
  end

  def teardown
    Subscriber.db[:subscribers].where(service: SERVICE, chat_id: @chat_id).delete
  end

  def test_concurrent_sends_advance_the_subscriber_one_block_at_a_time
    threads = 2.times.map do
      Thread.new { Sender.new.send @chat_id, noconfirm: true }
    end
    threads.each(&:value)

    assert_equal 2, IntegrationSender.calls.length
    assert_equal 2, IntegrationSender.calls.uniq.length
    assert_equal 2, Subscriber.where(service: SERVICE, chat_id: @chat_id).first.messages.length
    assert_equal 2, Subscriber.where(service: SERVICE, chat_id: @chat_id).first.last_sent.index
  end
end
