class UserFacingVersion < ActiveRecord::Base
  include Version

  belongs_to :content_item

  validates_with ContentItemUniquenessValidator

  def self.filter(content_item_scope, number:)
    join_content_items(content_item_scope)
      .where("user_facing_versions.number" => number)
  end

  def self.latest(content_item_scope)
    join_content_items(content_item_scope)
      .order("user_facing_versions.number asc")
      .last
  end

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "INNER JOIN user_facing_versions ON user_facing_versions.content_item_id = content_items.id"
    )
  end

  def self.fetch_for(content_item)
    where(content_item: content_item).pluck(:number).first
  end

private

  def content_item_target?
    true
  end

  def draft_and_live_version_numbers
    %w{draft published}.map do |state|
      targets = ContentItemFilter.similar_to(content_item, state: state, user_version: nil)
      self.class.where(content_item: targets).limit(1).pluck(:number)[0]
    end
  end
end
