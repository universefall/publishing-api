module Queries
  module GetWebContentItems
    def self.call(content_item_ids)
      results = PublishingAPI.service(:database)[:content_items]
        .select(
          :content_id,
          :description,
          :analytics_identifier,
          :title,
          :public_updated_at,
          :schema_name,
          :locations__base_path,
          :translations__locale
        )
        .select_more(
          :states__name___state, :user_facing_versions__number___user_facing_version
        )
        .join(:locations, content_item_id: :content_items__id)
        .join(:states, content_item_id: :content_items__id)
        .join(:translations, content_item_id: :content_items__id)
        .join(:user_facing_versions, content_item_id: :content_items__id)
        .where(content_items__id: content_item_ids)
        .all

      results.to_a.map do |r|
        WebContentItem.new(*r.values_at(*WebContentItem.members))
      end
    end
  end
end
