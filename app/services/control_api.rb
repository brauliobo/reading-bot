class ControlApi

  def self.launch
    @server ||= Thread.new do
      Rack::Server.new(app: App.freeze.app, Host: './run/control_api.socket').start
    end
  end

  class App < Roda
    route do |r|
      r.on 'scheduler' do
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
