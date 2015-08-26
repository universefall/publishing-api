Command = Module.new unless defined?(Command)

class Command::Redraft
  def name
    "redraft"
  end

  def call(event)
    content_id = event.payload['content_id']
    live = LiveContentItem.find_by_content_id!(content_id)
    DraftContentItem.create!(live.attributes.except("version"))
  end
end
