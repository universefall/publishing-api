class QueriesController < ApplicationController
  def process_query
    query = query_for(params[:query_name])
    response = query.call(params.except(:query_name))
    render json: response, status: response.response_code
  end

private
  def query_for(query_name)
    case query_name
    when "get_draft" then Query::GetDraft.new
    when "get_live" then Query::GetLive.new
    when "get_live_version" then Query::GetLiveVersion.new
    else
      raise "Unknown query '#{query_name}'"
    end
  end
end
