class LiveContentStore
  attr_reader :web_content_item, :payload_version

  def initialize(web_content_item, payload_version)
    @web_content_item = web_content_item
    @payload_version = payload_version
  end

  def send
    validate
    send_to_content_store
  end

  def validate
    if %w(published unpublished).exclude?(web_content_item.state)
      message = "Can only send published and unpublished items to live content store"
      raise DownstreamInvariantError.new(message)
    end
  end

  def store
    Adapters::ContentStore
  end
end

class WebContentPayload
  def initialize(web_content_item, base_path)
  end

  def payload
    return {
      withdrawal: web_content_item_payload,
      redirect: redirect_payload,
      gone: gone_payload
    }[unpublished.type] if web_content_item.state == 'unpublished'
    web_content_item_payload
  end

  def web_content_item_payload
    Presenters::ContentStorePresenter.present(
      web_content_item,
      payload_version,
      state_fallback_order: content_store::DEPENDENCY_FALLBACK_ORDER
    )
  end

  def redirect_payload
    payload = RedirectPresenter.present(
      base_path: web_content_item.base_path,
      publishing_app: web_content_item.publishing_app,
      destination: unpublishing.alternative_path,
      public_updated_at: unpublishing.created_at,
    )
    payload.merge!(payload_version: payload_version)
  end

  def gone_payload
    payload = GonePresenter.present(
      base_path: web_content_item.base_path,
      publishing_app: web_content_item.publishing_app,
      alternative_path: unpublishing.alternative_path,
      explanation: unpublishing.explanation,
    )
    payload.merge!(payload_version: payload_version)
  end
end

class DraftContentStore
  attr_reader :web_content_item, :payload_version
  def initialize(web_content_item, payload_version)
    @web_content_item = web_content_item
    @payload_version = payload_version
  end

  def send
    validate
    send_to_content_store
  end

  def validate
    if %w(draft published unpublished).exclude?(web_content_item.state)
      message = "Can only send draft, published and unpublished items to draft content store"
      raise DownstreamInvariantError.new(message)
    end
  end

  def store
    Adapters::DraftContentStore
  end
end

class DeleteContentStore
  attr_reader :base_path, :payload_version
  def initialize(_web_content_item, payload_version)
    @base_path = base_path
    @payload_version = payload_version
  end

  def send
    validate
    send_to_content_store
  end

  def validate
    if draft_base_path_conflict?
      message = "Cannot discard '#{base_path}' as there is an item occupying that base path"
      raise DiscardDraftBasePathConflictError.new(message)
    end
  end

  def draft_base_path_conflict?
    return false unless base_path
    ContentItemFilter.filter(
      base_path: base_path,
      state: %w(draft published unpublished),
    ).exists?
  end

  def store
    Adapters::DraftContentStore
  end
end
