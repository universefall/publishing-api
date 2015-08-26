require 'event_processor'
require 'command/create_draft'

class Services
  def event_processor
    EventProcessor.new.tap do |event_processor|
      commands.each do |command|
        event_processor.register_event_handler(command.name, command)
      end
    end
  end

private
  def commands
    [
      Command::CreateDraft.new,
      Command::ModifyDraft.new,
      Command::Publish.new,
      Command::Redraft.new
    ]
  end
end
