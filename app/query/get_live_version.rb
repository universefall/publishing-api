class Query::GetLiveVersion
  def call(params)
    content_item = LiveContentItemVersion.where(content_id: params[:content_id], version: params[:version_number]).first
    if content_item
      Query::SuccessResponse.new(content_item.attributes.except(:id))
    else
      Query::NotFoundResponse.new
    end
  end
end
