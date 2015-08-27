class Command::EditorialNote < Command::Base
  def self.command_name
    "editorial_note"
  end

  def call
    EditorialHistoryEvent.create(
      timestamp: Time.zone.now,
      content_id: content_id,
      user_id: event.user_id,
      action: event.name,
      event: event,
      version: latest_version || 1,
      note: event.payload['note']
    )
  end

private
  def content_id
    event.payload['content_id']
  end

  def latest_version
    @latest_version ||= LiveContentItemVersion.latest_version(content_id)
  end

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
