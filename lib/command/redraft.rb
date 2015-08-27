class Command::Redraft < Command::Base
  def self.command_name
    "redraft"
  end

  def call
    DraftContentItem.create!(attributes_for_new_draft)
  end

private
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
