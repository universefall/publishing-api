require "forwardable"

fields = %i{
  content_id description analytics_identifier title public_updated_at schema_name
  base_path locale state user_facing_version
}

WebContentItem = Struct.new(*fields) do
  def api_url
    return unless base_path
    Plek.current.website_root + "/api/content" + base_path
  end

  def web_url
    return unless base_path
    Plek.current.website_root + base_path
  end

  def description
    JSON.parse(self[:description])["value"]
  end
end
