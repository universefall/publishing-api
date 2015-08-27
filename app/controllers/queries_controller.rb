class QueriesController < ApplicationController
  def process_query
    query_class = query_for(params[:query_name])
    query = query_class.new(params.except(:query_name))
    response = query.call
    render json: response, status: response.response_code
  end

private
  def query_for(query_name)
    case query_name
    when "get_draft" then Query::GetDraft
    when "get_draft_history" then Query::GetDraftHistory
    when "get_live" then Query::GetLive
    when "get_live_version" then Query::GetLiveVersion
    else
      raise "Unknown query '#{query_name}'"
    end
  end
end
