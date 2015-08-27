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
  end
end
