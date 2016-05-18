class ContentItemUniquenessValidator < ActiveModel::Validator
  def validate(record)
    web_content_item = Queries::GetWebContentItems.(record.content_item_id).first
    return unless web_content_item

    state = record.name if record.is_a?(State)
    locale = record.locale if record.is_a?(Translation)
    base_path = record.base_path if record.is_a?(Location)
    user_facing_version = record.number if record.is_a?(UserFacingVersion)

    state ||= web_content_item.state
    locale ||= web_content_item.locale
    base_path ||= web_content_item.base_path
    user_facing_version ||= web_content_item.user_facing_version

    return unless state && locale && base_path && user_facing_version

    # For now, we have agreed to relax the validator so that you can have
    # duplicates with a state of unpublished. The reason for doing this is because
    # we think that the 'gone' and 'redirect' mechanisms are modelled incorrect
    # and need to be revisited.
    #
    # As it stands right now, when these content items are sent to the
    # Publishing API, they have the side-effect of unpublishing other content
    # items. We think think that this should change in the future.
    return if state == "unpublished"

    other_content_items = ContentItem.where("content_items.id <> #{web_content_item.id}")
    matching_items = ContentItemFilter.new(scope: other_content_items).filter(
      state: state,
      locale: locale,
      base_path: base_path,
      user_version: user_facing_version,
    )

    if matching_items.any?
      error = "conflicts with a duplicate: "
      error << "state=#{state}, "
      error << "locale=#{locale}, "
      error << "base_path=#{base_path}, "
      error << "user_version=#{user_facing_version}"

      record.errors.add(:content_item, error)
    end
  end
end
