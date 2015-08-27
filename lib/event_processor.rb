require 'event'

class EventProcessor
  class InvalidUser < StandardError; end

  def initialize
    @handlers = {}
  end

  def process(name, user_id, payload)
    user = User.find_by_id(user_id) or raise InvalidUser

    Event.connection.transaction do
      event = Event.create(name: name, user: user, payload: payload)
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
