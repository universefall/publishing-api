class Query::GetDraftHistory < Query::Base
  def call
    if editorial_history_events.any?
      Response::Success.new(presented_history)
    else
      Response::NotFound.new
    end
  end

private
  def editorial_history_events
    @history ||= EditorialHistoryEvent.where(content_id: params[:content_id]).order(:id)
  end

  def presented_history
    editorial_history_events.map do |editorial_history_event|
      EventPresenter.new(editorial_history_event).call
    end
  end

  class EventPresenter
    attr_reader :event

    def initialize(event)
      @event = event
    end

    def call
      present_core_event.merge(maybe_note)
    end

  private
    def present_core_event
      {
        "timestamp" => event.timestamp.iso8601,
        "user_id" => event.user_id,
        "action" => event.action,
        "event_id" => event.event_id,
        "version" => event.version
      }
    end

    def maybe_note
      if event.action == 'editorial_note'
        { "note" => event.note }
      else
        {}
      end
    end
  end
end
