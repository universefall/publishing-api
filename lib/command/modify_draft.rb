class Command::ModifyDraft < Command::Base
  def self.command_name
    "modify_draft"
  end

  def call
    content_id = event.payload['content_id']
    draft = DraftContentItem.find_by_content_id!(content_id)
    event.payload.each do |k, v|
      draft.send("#{k}=", v)
    end
    draft.save!
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
      version: version
    )
  end

  def content_id
    event.payload['content_id']
  end

  def live_version
    LiveContentItem.find_by_content_id(content_id).try(:version) || 0
  end

  def version
    live_version + 1
  end
end
