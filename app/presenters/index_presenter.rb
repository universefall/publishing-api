class IndexPresenter
  attr_reader :item

  def initialize(item)
    @item = item
  end

  def as_json
    {
      base_path: item.base_path,
      content_id: item.content_id,
      links: item.links,
      title: item.title,
      state: item.state,
      updated_at: item.updated_at,
      version: item.version,
    }
  end
end
