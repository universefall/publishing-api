class Query::GetLiveVersion
  def call(params)
    content_item = LiveContentItemVersion.where(content_id: params[:content_id], version: params[:version_number]).first
    if content_item
      Response::Success.new(content_item.attributes.except(:id))
    else
      Response::NotFound.new
    end
  end
end
