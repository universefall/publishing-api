class ContentItem < ActiveRecord::Base
  include DefaultAttributes
  include SymbolizeJSON
  include DescriptionOverrides

  DEFAULT_LOCALE = "en".freeze

  TOP_LEVEL_FIELDS = [
    :analytics_identifier,
    :content_id,
    :description,
    :details,
    :document_type,
    :first_published_at,
    :last_edited_at,
    :need_ids,
    :phase,
    :public_updated_at,
    :publishing_app,
    :redirects,
    :rendering_app,
    :routes,
    :schema_name,
    :title,
    :update_type,
  ].freeze

  NON_RENDERABLE_FORMATS = %w(redirect gone).freeze
  EMPTY_BASE_PATH_FORMATS = %w(contact government).freeze

  scope :renderable_content, -> { where.not(document_type: NON_RENDERABLE_FORMATS) }

  validates :schema_name, presence: true
  validates :document_type, presence: true

  validates :content_id, presence: true, uuid: true
  validates :publishing_app, presence: true
  validates :title, presence: true, if: :renderable_content?
  validates :rendering_app, presence: true, dns_hostname: true, if: :requires_rendering_app?
  validates :phase, inclusion: {
    in: %w(alpha beta live),
    message: 'must be either alpha, beta, or live'
  }
  validates :description, well_formed_content_types: { must_include: "text/html" }
  validates :details, well_formed_content_types: { must_include_one_of: %w(text/html text/govspeak) }

  def requires_base_path?
    EMPTY_BASE_PATH_FORMATS.exclude?(document_type)
  end

  def pathless?
    !self.requires_base_path? && !Location.exists?(content_item: self)
  end

  # FIXME: This is here just for the process of applying govspeak rendering
  def details_for_govspeak_conversion
    return details unless details.is_a?(Hash)

    value_without_html = lambda do |value|
      wrapped = Array.wrap(value)
      html = wrapped.find { |item| item.is_a?(Hash) && item[:content_type] == "text/html" }
      govspeak = wrapped.find { |item| item.is_a?(Hash) && item[:content_type] == "text/govspeak" }
      if html && govspeak
        govspeak[:content] = replace_specialist_publisher_inline_attachments(govspeak[:content], details[:attachments])
        wrapped - [html]
      else
        value
      end
    end

    details.deep_dup.each_with_object({}) do |(key, value), memo|
      memo[key] = value_without_html.call(value)
    end
  end

private

  def renderable_content?
    NON_RENDERABLE_FORMATS.exclude?(document_type)
  end

  def requires_rendering_app?
    renderable_content? && document_type != "contact"
  end


  # FIXME: This is here just for the process of applying govspeak rendering
  def replace_specialist_publisher_inline_attachments(govspeak, attachments)
    return nil unless govspeak

    sanitise_filename = lambda do |filename|
      filename.split("/").last.downcase.gsub(/[^a-zA-Z0-9]/, "_")
    end

    find_specialist_publisher_attachment = lambda do |identifying_string|
      return nil unless attachments
      sanitised_input = sanitise_filename.call(identifying_string)
      attachments.detect do |a|
        sanitised_match = sanitise_filename.call(a[:url] || a[:content_id])
        sanitised_input == sanitised_match
      end
    end

    replace_images = lambda do |_|
      attachment = find_specialist_publisher_attachment.call(Regexp.last_match[1])
      attachment ? "[embed:attachments:image:#{attachment[:content_id]}]" : ""
    end

    replace_attachments = lambda do |_|
      attachment = find_specialist_publisher_attachment.call(Regexp.last_match[1])
      attachment ? "[embed:attachments:inline:#{attachment[:content_id]}]" : ""
    end

    govspeak
      .gsub(/!\[InlineAttachment:(.+?)\]/, &replace_images)
      .gsub(/\[InlineAttachment:(.+?)\]/, &replace_attachments)
  end
end
