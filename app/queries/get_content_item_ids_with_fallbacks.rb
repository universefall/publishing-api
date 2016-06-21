module Queries
  module GetContentItemIdsWithFallbacks
    def self.order_by_clause(attribute, values)
      Sequel.case(
        values.map.with_index { |v,i| [v, i] }.to_h,
        values.size,
        attribute
      )
    end

    def self.call(content_ids, locale_fallback_order: ContentItem::DEFAULT_LOCALE, state_fallback_order:)
      state_fallback_order = Array(state_fallback_order).map(&:to_s)
      locale_fallback_order = Array(locale_fallback_order).map(&:to_s)

      fallbacks = PublishingAPI.service(:database)[:content_items]
        .select(
          :content_items__id,
          :content_items__content_id,
        )
        .join(:states, content_item_id: :content_items__id)
        .join(:translations, content_item_id: :content_items__id)
        .where(
          content_items__content_id: content_ids,
          states__name: state_fallback_order,
          translations__locale: locale_fallback_order
        )
        .order(
          order_by_clause(:states__name, state_fallback_order),
          order_by_clause(:translations__locale, locale_fallback_order)
        )

      aggregates = PublishingAPI.service(:database)[:fallbacks]
        .with(:fallbacks, fallbacks)
        .group(:content_id)
        .select(Sequel.as(Sequel.function(:array_agg, :fallbacks__id), :ids))

      PublishingAPI.service(:database)[:aggregates]
        .with(:aggregates, aggregates)
        .select(Sequel.subscript(:aggregates__ids, 1).as(:id))
    end
  end
end
