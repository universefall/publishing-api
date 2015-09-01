class Query::GetDraft < Query::Base
  def call
    content_item = DraftContentItem.find_by_content_id(params[:content_id])
    if content_item
      Response::Success.new(present(content_item))
    else
      Response::NotFound.new
    end
  end

  def present(content_item)
    content_item
      .attributes
      .except("id", "user_id")
      .merge(
        "available_workflow_actions" => ["publish"]
      )
  end
end
