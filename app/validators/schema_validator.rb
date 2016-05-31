require 'json-schema'

class SchemaValidator
  def initialize(payload, type:, schema_name: nil, schema: nil)
    @payload = payload
    @type = type
    @schema = schema
    @schema_name = schema_name
  end

  def validate
    validate_schema
  end

private

  attr_reader :payload, :type

  def validate_schema
    JSON::Validator.validate!(schema, payload)
  rescue JSON::Schema::ValidationError => error
    Airbrake.notify_or_ignore(error, parameters: {
      explanation: "#{payload} schema validation error"
    })
    false
  end

  def schema
    @schema || File.read("govuk-content-schemas/formats/#{schema_name}/publisher_v2/#{type}.json")
  rescue Errno::ENOENT => error
    Airbrake.notify_or_ignore(error, parameters: {
      explanation: "#{payload} is missing schema_name #{schema_name} or type #{type}"
    })
    return {}
  end

  def schema_name
    @schema_name || payload[:schema_name] || payload[:format]
  end
end