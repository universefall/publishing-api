class ContentItem
  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  field :content_id, :type => String, :overwrite => true, default: ->{ SecureRandom.uuid }
  field :version, :type => Integer, default: 1
  field :base_path, :type => String
  field :state, :type => String, default: "draft"
  field :title, :type => String
  field :description, :type => String
  field :format, :type => String
  field :locale, :type => String, :default => I18n.default_locale.to_s
  field :need_ids, :type => Array, :default => []
  field :public_updated_at, :type => DateTime
  field :details, :type => Hash, :default => {}
  field :publishing_app, :type => String
  field :rendering_app, :type => String
  field :routes, :type => Array, :default => []
  field :redirects, :type => Array, :default => []
  field :links, :type => Hash, :default => {}
  field :access_limited, :type => Hash, :default => {}
  attr_accessor :update_type

  validates :base_path, presence: true #, absolute_path: true
  validates :content_id, presence: true # uuid: true, allow_nil: true
  validates :format, :publishing_app, presence: true
  validates :state, inclusion: { in: ["draft", "published", "submitted", "withdrawn"] }

  def as_json(*args)
    super.merge(
      available_workflow_actions: available_workflow_actions,
    )
  end

  def available_workflow_actions
    {
      "draft" => [
        "publish",
        "submit",
      ],
      "published" => [
        "withdraw",
      ],
      "submitted" => [
        "reject",
        "publish",
      ],
      "withdrawn" => [
        "redraft",
      ]
    }[state]
  end
end
