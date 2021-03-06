module Presenters
  module Queries
    class ExpandedLinkSet
      def initialize(content_id:, state_fallback_order:, locale_fallback_order: ContentItem::DEFAULT_LOCALE)
        @content_id = content_id
        @state_fallback_order = Array(state_fallback_order)
        @locale_fallback_order = Array(locale_fallback_order)
      end

      def links
        @links ||= dependees.merge(dependents).merge(translations)
      end

      def web_content_items(target_content_ids)
        return [] unless target_content_ids.present?
        ::Queries::GetWebContentItems.(
          ::Queries::GetContentItemIdsWithFallbacks.(
            target_content_ids,
            locale_fallback_order: locale_fallback_order,
            state_fallback_order: state_fallback_order
          )
        )
      end

    private

      attr_reader :state_fallback_order, :locale_fallback_order, :content_id

      def dependees
        ExpandDependees.new(content_id, self).expand
      end

      def dependents
        ExpandDependents.new(content_id, self).expand
      end

      def translations
        AvailableTranslations.new(content_id, state_fallback_order).translations
      end
    end
  end
end
