module Command
  class Base
    attr_reader :event

    def initialize(event)
      @event = event
    end
  end
end
