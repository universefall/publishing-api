class Command::Redraft < Command::Base
  def self.command_name
    "redraft"
  end

  def call
    content_id = event.payload['content_id']
    live = LiveContentItem.find_by_content_id!(content_id)
    DraftContentItem.create!(live.attributes.except("version"))
  end
end
