class LinkSet < ActiveRecord::Base
  has_many :link_items, class_name: 'Link'
  include Replaceable
  include DefaultAttributes
  include SymbolizeJSON

  # def links=(links_hash)
  #   create_or_replace_links(links_hash) if links_valid?(links_hash)
  # end
  #
  # def links
  #   links = Link.where(link_set_id: self.id)
  #
  #   links_hash = Hash.new
  #
  #   links.each do |l|
  #     if links_hash.has_key?(l.link_type)
  #       links_hash[l.link_type] << l.target_content_id
  #     else
  #       links_hash[l.link_type.to_sym] = [l.target_content_id]
  #     end
  #   end
  #
  #   SymbolizeJSON.symbolize(links_hash)
  # end

  def links_valid?(links)
    # Test that the `links` attribute, if set, is a hash from strings to lists
    # of UUIDs
    return true if links.empty?

    bad_keys = links.keys.reject { |key| link_key_is_valid?(key) }
    unless bad_keys.empty?
      errors[:links] = "Invalid link types: #{bad_keys.to_sentence}"
    end

    bad_values = links.values.reject { |value|
      value.is_a?(Array) && value.all? { |content_id|
        UuidValidator.valid?(content_id)
      }
    }
    if bad_values.any?
      errors[:links] = "must map to lists of UUIDs"
    end

    true if bad_keys.empty? && bad_values.empty?
  end

  def link_key_is_valid?(link_key)
    link_key.is_a?(String) &&
      link_key.to_s.match(/\A[a-z0-9_]+\z/) &&
      link_key != "available_translations"
  end

private
  def self.query_keys
    [:content_id]
  end

  def create_or_replace_links(links)
    content_item_links = Link.where(link_set: self)

    if links.nil? || links.empty?
      delete_old_content_item_links
    elsif content_item_links.empty?
      add_content_item_links(links)
    else
      delete_old_content_item_links
      add_content_item_links(links)
    end
  end

  def add_content_item_links(links)
    links.each do |link_type, links|
      links.each do |link|
        Link.new(
          link_set: self,
          target_content_id: link,
          link_type: link_type,
        ).save!
      end
    end
  end

  def delete_old_content_item_links
    Link.where(link_set: self).delete_all
  end

end
