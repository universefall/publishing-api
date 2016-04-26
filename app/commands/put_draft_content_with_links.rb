module Commands
  class PutDraftContentWithLinks < BaseCommand
    def call
      if payload[:content_id]
        content_with_links.update_content_item(v2_put_content_payload, v2_put_link_set_payload)
      else
        content_with_links.create_content_item(payload)
      end

      Success.new(payload)
    end

  private

    def content_with_links
      @content_with_links ||= ContentWithLinks.new(payload, downstream, event)
    end

    def v2_put_content_payload
      payload
        .except(:links)
    end

    def v2_put_link_set_payload
      payload
        .slice(:content_id, :links)
        .merge(links: payload[:links] || {})
    end
  end
end
