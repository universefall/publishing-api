require 'event'

class EventProcessor
  class InvalidUser < StandardError; end

  class ProcessingError < StandardError
    attr_reader :response
    def initialize(response)
      @response = response
      super("processing error")
    end
  end

  def initialize
    @handlers = {}
  end

  def process(name, user_id, payload)
    user = User.find_by_id(user_id) or raise InvalidUser

    Event.connection.transaction do
      event = Event.create(name: name, user: user, payload: payload)
      handler_classes_for(name).each do |handler_class|
        handler_class.new(event).call
      end
      event
    end
  end

  def register_event_handler(name, handler_class)
    @handlers[name] ||= []
    @handlers[name] << handler_class
  end

private
  def handler_classes_for(name)
    @handlers.fetch(name, [])
  end
end
