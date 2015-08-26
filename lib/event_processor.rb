require 'event'

class EventProcessor
  def initialize
    @handlers = {}
  end

  def process(name, payload)
    Event.connection.transaction do
      event = Event.create(name: name, payload: payload)
      handlers_for(name).each do |handler|
        handler.call(event)
      end
      event
    end
  end

  def register_event_handler(name, handler)
    @handlers[name] ||= []
    @handlers[name] << handler
  end

private
  def handlers_for(name)
    @handlers.fetch(name, [])
  end
end
