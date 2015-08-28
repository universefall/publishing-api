class ContentItemsController < ApplicationController
  include URLArbitration

  before_filter :parse_request_data, only: [:create, :update]
  before_filter :find_item, except: [:index]

  attr_reader :item

  def index
    items = ContentItem.asc(:content_id).asc(:version)
    item_hash = {}
    items.each do |content_item|
      id = content_item.content_id
      if item_hash.has_key?(id)
        item_hash[id][:state] << ' with new draft'
      else
        item_hash[id] = IndexPresenter.new(content_item).as_json
      end
    end
    data = item_hash.values.sort_by { |element| element[:updated_at] }
    render json: data
  end

  def show
    render json: item
  end

  def create
    @item = ContentItem.new
    update_item(:create)
  end

  def update
    action = item.state == 'published' ? :new_version : :update
    update_item(action)
  end

  def submit
    if item.state == "draft"
      item.update(state: "submitted")
      render json: {}, status: :ok
      # send notifications
    else
      render json: {}, status: :method_not_allowed
    end
  end

  def reject
    if item.state == "submitted"
      item.update(state: "draft")
      render json: {}, status: :ok
      # send notifications
    else
      render json: {}, status: :method_not_allowed
    end
  end

  def publish
    if %w(submitted draft).include?(item.state)
      item.update(state: 'published')
      render json: {}, status: :ok
      # send notifications
    else
      render json: {}, status: :method_not_allowed
    end
  end

  def withdraw
    if item.state == 'published'
      item.update(state: 'withdrawn')
      render json: {}, status: :ok
      # send notifications
    else
      render json: {}, status: :method_not_allowed
    end
  end

  def redraft
    if item.state == "withdrawn"
      update_item(:new_version)
    else
      render json: {}, status: :method_not_allowed
    end
  end

private

  def forbidden_attributes
    [:_id, :state, :version]
  end

  def find_item
    @item = ContentItem.where(content_id: params[:content_id]).last
  end

  def update_item(action)
    if action == :new_version
      new_version = item.clone
      new_version.version += 1
      new_version.state = "draft"
      @item = new_version
    end

    item.assign_attributes(request_data)

    if item.save
      status = action == :create ? :created : :ok
    else
      status = :unprocessable_entity
    end
    response_body = { content_id: item.content_id }
    response_body[:errors] = item.errors.as_json if item.errors.any?
    render :json => response_body, :status => status
  end

end
