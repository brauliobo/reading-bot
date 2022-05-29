class ControlApi

  def self.launch
    @server ||= Thread.new do
      Rack::Server.new(app: App.freeze.app, Host: './run/control_api.socket').start
    end
  end

  class App < Roda
    route do |r|
      r.on 'scheduler' do
        r.get 'dry_enable' do
          Sender.dry = true
        end
        r.get 'dry_disable' do
          Sender.dry = false
        end

        r.get 'send_enabled' do
          Sender.new.send_enabled
          'sent'
        end
        r.get 'reload' do
          Scheduler.reload
          'finished'
        end
        r.get 'restart' do
          Scheduler.restart
          'finished'
        end
      end
    end
  end

end
