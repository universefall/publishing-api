class PublishIntentsController < ApplicationController
  def show
    render json: Queries::GetPublishIntent.call(base_path)
  end

  def create_or_update
    response = Commands::PutPublishIntent.call(content_item)
    render status: response.code, json: response
  end

  def destroy
    response = Commands::DeletePublishIntent.call(base_path: base_path)
    render status: response.code, json: response
  end

private

  def content_item
    payload.merge(base_path: base_path)
  end
end
