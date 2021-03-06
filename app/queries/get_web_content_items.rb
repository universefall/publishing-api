module Queries
  class GetWebContentItems
    extend ArelHelpers

    def self.call(content_item_ids, presenter = WebContentItem)
      content_items = ContentItem.arel_table
      filtered = scope
        .where(content_items[:id].in(content_item_ids))
      get_rows(filtered).map do |row|
        presenter.from_hash(row)
      end
    end

    def self.find(content_item_id)
      call(content_item_id).first
    end

    def self.for_content_store(content_id, locale, include_draft = false)
      unpublishings = Unpublishing.arel_table

      allowed_states = [:published, :unpublished]
      allowed_states << :draft if include_draft
      filtered = scope(UserFacingVersion.arel_table[:number].desc)
        .where(ContentItem.arel_table[:content_id].eq(content_id))
        .where(Translation.arel_table[:locale].eq(locale))
        .where(State.arel_table[:name].in(allowed_states))
        .where(
          unpublishings[:type].eq(nil).or(
            unpublishings[:type].not_eq("substitute")
          )
        )
        .take(1)
      results = get_rows(filtered).map do |row|
        WebContentItem.from_hash(row)
      end
      results.first
    end

    def self.scope(order = nil)
      content_items = ContentItem.arel_table
      locations = Location.arel_table
      states = State.arel_table
      translations = Translation.arel_table
      unpublishings = Unpublishing.arel_table
      user_facing_versions = UserFacingVersion.arel_table

      content_items
        .project(
          content_items[:id],
          content_items[:analytics_identifier],
          content_items[:content_id],
          content_items[:description],
          content_items[:details],
          content_items[:document_type],
          content_items[:first_published_at],
          content_items[:last_edited_at],
          content_items[:need_ids],
          content_items[:phase],
          content_items[:public_updated_at],
          content_items[:publishing_app],
          content_items[:redirects],
          content_items[:rendering_app],
          content_items[:routes],
          content_items[:schema_name],
          content_items[:title],
          content_items[:update_type],
          locations[:base_path],
          states[:name].as("state"),
          translations[:locale],
          user_facing_versions[:number].as("user_facing_version")
        )
        .outer_join(locations).on(content_items[:id].eq(locations[:content_item_id]))
        .join(states).on(content_items[:id].eq(states[:content_item_id]))
        .join(translations).on(content_items[:id].eq(translations[:content_item_id]))
        .join(user_facing_versions).on(content_items[:id].eq(user_facing_versions[:content_item_id]))
        .outer_join(unpublishings).on(
          content_items[:id].eq(unpublishings[:content_item_id])
            .and(states[:name].eq("unpublished"))
        )
        .order(order || content_items[:id].asc)
    end
  end
end
