class ContentItemFilter
  def initialize(scope: ContentItem.all)
    self.scope = scope
  end

  def self.similar_to(content_item, params = {})
    params = params.dup

    params[:locale] = translation(content_item) unless params.has_key?(:locale)
    params[:base_path] = location(content_item) unless params.has_key?(:base_path)
    params[:state] = state(content_item) unless params.has_key?(:state)
    params[:user_version] = user_facing_version(content_item) unless params.has_key?(:user_version)

    scope = ContentItem.where(content_id: content_item.content_id)

    new(scope: scope).filter(params)
  end

  def self.filter(**args)
    self.new.filter(**args)
  end

  def filter(locale: nil, base_path: nil, state: nil, user_version: nil)
    scope = self.scope
    scope = Location.filter(scope, base_path: base_path) if base_path
    scope = Translation.filter(scope, locale: locale) if locale
    scope = State.filter(scope, name: state) if state
    scope = UserFacingVersion.filter(scope, number: user_version) if user_version
    scope
  end

  def self.translation(content_item)
    Translation.fetch_for(content_item)
  end

  def self.location(content_item)
    Location.fetch_for(content_item)
  end

  def self.state(content_item)
    State.fetch_for(content_item)
  end

  def self.user_facing_version(content_item)
    UserFacingVersion.fetch_for(content_item)
  end

protected

  attr_accessor :scope
end
