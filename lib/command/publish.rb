Command = Module.new unless defined?(Command)

class Command::Publish
  def name
    "publish"
  end

  def call(event)
    content_id = event.payload['content_id']
    draft = DraftContentItem.find_by_content_id!(content_id)
    latest_version = LiveContentItemVersion.latest_version(content_id)
    version = latest_version ? latest_version + 1 : 1
    new_attributes = draft.attributes.merge("version" => version).except("id")
    existing = LiveContentItem.find_by_content_id(content_id)
    if existing
      existing.update_attributes!(new_attributes)
    else
      LiveContentItem.create!(new_attributes)
    end
    LiveContentItemVersion.create!(new_attributes)
    draft.destroy!
  end
end
