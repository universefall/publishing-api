Command = Module.new unless defined?(Command)

class Command::ModifyDraft
  def name
    "modify_draft"
  end

  def call(event)
    content_id = event.payload['content_id']
    draft = DraftContentItem.find_by_content_id!(content_id)
    event.payload.each do |k, v|
      draft.send("#{k}=", v)
    end
    draft.save!
  end
end
