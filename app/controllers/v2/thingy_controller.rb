module V2

  # (first pass - we might make it more flexible than this)
  # This controller provides endpoints exposing latest version of content.
  # Content is represented hierarchically, governed by content_id.
  # Note that this will tend to hide the internal concept of content_item from the user.
  class ThingyController < ApplicationController

    def index

      # input:
      ## new params
      # last_seen_content_id=content_id
      # count=integer

      # output:
      # json:
      # response:= [content] (nb ordered list)
      # content:= {content_id, links, [content_item]}
      # links:= {link_type: [content_id]}
      # content_item:{locale, state, base_path, user_facing_version, data???}



      ## fixme we need to pass in the latest seen content_id to paginate properly
      # pagination = Pagination.new(query_params)

      ## new query
      ## new presenter
      ## etc



      # results = Queries::GetContentCollection.new(
      #     document_type: doc_type,
      #     fields: query_params[:fields],
      #     filters: filters,
      #     pagination: pagination,
      #     search_query: query_params.fetch("q", "")
      # )
      #
      # render json: Presenters::ResultsPresenter.new(results, pagination, request.original_url).present

      render json: Presenters::ResultsPresenter.new([{}, {}], Pagination.new, 'foo')

    end

  end
end