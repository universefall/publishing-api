class Command::CreateDraft < Command::Base
  def self.command_name
    "create_draft"
  end

  def call
    attrs = event.payload.reject { |k,_| ignored_attributes.include?(k) }
    DraftContentItem.create!(attrs)
    log_editorial_history_event!
  end

private
  def log_editorial_history_event!
    EditorialHistoryEvent.create(
      timestamp: Time.zone.now,
      content_id: event.payload['content_id'],
      user_id: event.user_id,
      action: event.name,
      event: event,
      version: 1
    )
  end

  def ignored_attributes
    %w{
      update_type
    }
  end
end
