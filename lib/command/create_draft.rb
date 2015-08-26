Command = Module.new unless defined?(Command)

class Command::CreateDraft
  def name
    "create_draft"
  end

  def call(event)
    attrs = event.payload.reject { |k,_| ignored_attributes.include?(k) }
    DraftContentItem.create!(attrs)
  end

  def ignored_attributes
    %w{
      update_type
    }
  end
end
