class LiveContentItemVersion < ActiveRecord::Base
  validates :content_id, presence: true

  def self.latest_version(content_id)
    latest = LiveContentItemVersion.where(content_id: content_id).order("version desc").limit(1).select(:version).first
    latest && latest.version
  end
end
