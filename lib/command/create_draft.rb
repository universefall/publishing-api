class Command::CreateDraft < Command::Base
  def self.command_name
    "create_draft"
  end

  def call
    attrs = event.payload.reject { |k,_| ignored_attributes.include?(k) }
    DraftContentItem.create!(attrs)
  end

  def ignored_attributes
    %w{
      update_type
    }
  end
end
