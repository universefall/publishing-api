class Command::Redraft < Command::Base
  def self.command_name
    "redraft"
  end

  def call
    DraftContentItem.create!(attributes_for_new_draft)
    log_editorial_history_event!
  end

private
  def log_editorial_history_event!
    EditorialHistoryEvent.create(
      timestamp: Time.zone.now,
      content_id: content_id,
      user_id: event.user_id,
      action: event.name,
      event: event,
      version: live_content_item.version
    )
  end

  def attributes_for_new_draft
    live_content_item.attributes.except("id", "version").tap do |attributes|
      attributes['details'].delete("change_history")
    end
  end

  def live_content_item
    @live_content_item ||= LiveContentItem.find_by_content_id!(content_id)
  end

  def content_id
    event.payload['content_id']
  end
end
