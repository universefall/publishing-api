Command = Module.new unless defined?(Command)

class Command::Publish
  def name
    "publish"
  end

  def call(event)
    content_id = event.payload['content_id']
    draft = DraftContentItem.find_by_content_id!(content_id)
    LiveContentItem.create!(draft.attributes)
    draft.destroy!
  end
end
