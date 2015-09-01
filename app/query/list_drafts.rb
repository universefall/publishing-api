class Query::ListDrafts < Query::Base
  def call
    Response::Success.new(drafts)
  end

private
  def drafts
    DraftContentItem.all.map do |item|
      present_item(item)
    end
  end

  def present_item(item)
    {
      base_path: item.base_path,
      content_id: item.content_id,
      links: item.links,
      title: item.title,
      state: 'draft',
      updated_at: item.public_updated_at,
      version: LiveContentItemVersion.latest_version(item.content_id),
    }
  end
end
