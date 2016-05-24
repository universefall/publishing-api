class State
  include SupportingObject
  extend Forwardable

  def_delegators :content_item, :name, :name=

  def self.supersede(content_item)
    change_state(content_item, name: "superseded")
  end

  def self.publish(content_item)
    change_state(content_item, name: "published")
  end

  def self.unpublish(content_item, type:, explanation: nil, alternative_path: nil)
    change_state(content_item, name: "unpublished")

    unpublishing = Unpublishing.find_by(content_item: content_item)

    if unpublishing.present?
      unpublishing.update_attributes(
        type: type,
        explanation: explanation,
        alternative_path: alternative_path,
      )
    else
      Unpublishing.create!(
        content_item: content_item,
        type: type,
        explanation: explanation,
        alternative_path: alternative_path,
      )
    end
  end

  def self.substitute(content_item)
    unpublish(content_item,
      type: "substitute",
      explanation: "Automatically unpublished to make way for another content item",
    )
  end

  def self.change_state(content_item, name:)
    state = self.find_by!(content_item: content_item)
    state.update_attributes!(name: name)
  end
  private_class_method :change_state
end
