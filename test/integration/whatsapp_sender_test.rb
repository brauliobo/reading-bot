require 'test_helper'

class WhatsappSenderIntegrationTest < Minitest::Test
  def test_returns_a_delivery_record_after_whatsapp_accepts_a_message
    response = {'id' => {'_serialized' => 'message-1'}}
    WhatsappSender.stub :start, true do
      WhatsappSender.stub :send_message, response do
        message = WhatsappSender.new.send_paras 'chat', ['A paragraph']

        assert_equal 'message-1', message.id
        assert_equal '_*A paragraph*_', message.text
        assert message.sent_at
      end
    end
  end
end
