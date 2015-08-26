class LiveContentItem < ActiveRecord::Base
  validates :content_id, presence: true
end
