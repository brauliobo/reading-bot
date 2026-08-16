require 'test_helper'

class TelegramSenderIntegrationTest < Minitest::Test
  FakeApi = Struct.new(:sent) do
    def send_message params
      self.sent = params
      Telegram::Bot::Types::Message.new(
        message_id: 123,
        date:       1_700_000_000,
        chat:       {id: params[:chat_id].to_i, type: 'supergroup'},
      )
    end
  end

  def test_returns_a_delivery_record_from_a_typed_telegram_response
    api = FakeApi.new
    TelegramSender.bot = Struct.new(:api).new(api)

    message = TelegramSender.new.send_paras '-1001@11', ['A paragraph']

    assert_equal 123, message.id
    assert_equal '<i><b>A paragraph</b></i>', message.text
    assert_equal Time.at(1_700_000_000), message.sent_at
    assert_equal '-1001', api.sent[:chat_id]
    assert_equal '11', api.sent[:message_thread_id]
  ensure
    TelegramSender.bot = nil
    TelegramSender.running = false
  end
end
