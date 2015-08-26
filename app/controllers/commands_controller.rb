class CommandsController < ApplicationController
  def process_command
    event = event_processor.process(params['command_name'], request_json)

    render json: {event_id: event.id}
  end

private
  def request_json
    @request_json ||= JSON.parse(request.body.read)
  rescue JSON::ParserError
    head :bad_request
  end

  def event_processor
    Services.new.event_processor
  end
end
