require 'event_processor'
require 'command/create_draft'

class Services
  def event_processor
    EventProcessor.new.tap do |event_processor|
      commands.each do |command|
        event_processor.register_event_handler(command.command_name, command)
      end
    end
  end

private
  def commands
    [
      Command::CreateDraft,
      Command::ModifyDraft,
      Command::Publish,
      Command::Redraft
    ]
  end
end
