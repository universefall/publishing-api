module Commands
  class PutContentWithLinks < BaseCommand
    def call
      if payload[:content_id]
        content_with_links.update_content_item(v2_put_content_payload, v2_put_link_set_payload)
        V2::Publish.call(v2_publish_payload, downstream: downstream)
      elsif downstream
        content_store_payload = content_with_links.create_content_item(payload.except(:access_limited))
        Adapters::ContentStore.put_content_item(payload.fetch(:base_path), content_store_payload)

        message_bus_payload = Presenters::DownstreamPresenter::V1.present(
          payload.except(:access_limited),
          event,
        )
        PublishingAPI.service(:queue_publisher).send_message(message_bus_payload)
      end

      Success.new(payload)
    end

  private

    def content_with_links
      @content_with_links ||= ContentWithLinks.new(payload.except(:access_limit), downstream, event)
    end

    def v2_put_content_payload
      payload
        .except(:access_limited, :links)
    end

    def v2_put_link_set_payload
      payload
        .slice(:content_id, :links)
        .merge(links: payload[:links] || {})
    end

    def v2_publish_payload
      payload
        .except(:access_limited)
        .merge(update_type: payload[:update_type] || "major")
    end
  end
end
