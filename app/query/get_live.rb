class Query::GetLive
  def call(params)
    content_item = LiveContentItem.find_by_content_id(params[:content_id])
    if content_item
      Response::Success.new(content_item.attributes.except(:id))
    else
      Response::NotFound.new
    end
  end
end
