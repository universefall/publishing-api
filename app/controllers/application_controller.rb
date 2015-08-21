class ApplicationController < ActionController::Base

private

  def forbidden_attributes
    []
  end

  def base_path
    "/#{params[:base_path]}"
  end

  def parse_request_data
    @request_data = JSON.parse(request.body.read).deep_symbolize_keys
    if (request_data.keys & forbidden_attributes).present?
      head :unprocessable_entity
    end
  rescue JSON::ParserError
    head :bad_request
  end

  attr_reader :request_data
end
