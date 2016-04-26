module Commands
  class ContentWithLinks
    def initialize(payload, downstream, event)
      @payload = payload
      @downstream = downstream
      @event = event
    end

    def update_content_item(content, link_set)
      delete_existing_links

      V2::PutContent.call(content, downstream: downstream)
      V2::PatchLinkSet.call(link_set, downstream: downstream)
    end

    def create_content_item(payload)
      PathReservation.reserve_base_path!(base_path, payload[:publishing_app])
      return unless downstream

      Adapters::DraftContentStore.put_content_item(base_path, content_store_payload)
      content_store_payload
    end

  private

    attr_reader :payload, :downstream, :event

    def base_path
      payload.fetch(:base_path)
    end

    def delete_existing_links
      link_set = LinkSet.find_by(content_id: payload[:content_id])
      return unless link_set

      links = link_set.links.where.not(link_type: protected_link_types)
      links.destroy_all
    end

    def protected_link_types
      ["alpha_taxons"]
    end

    def content_store_payload
      Presenters::DownstreamPresenter::V1.present(
        payload,
        event,
        update_type: false
      )
    end
  end
end
