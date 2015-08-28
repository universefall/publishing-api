Rails.application.routes.draw do

  scope format: false do |r|

    resources :content_items, param: :content_id, path: "content-items" do
      member do
        put 'submit'
        put 'reject'
        put 'publish'
        put 'withdraw'
        put 'redraft'
      end
    end
  #   put "/draft-content(/*base_path)", to: "content_items#put_draft_content_item"
  #   put "/content(/*base_path)", to: "content_items#put_live_content_item"
  #
  #   put "/publish-intent(/*base_path)", to: "publish_intents#create_or_update"
  #   get "/publish-intent(/*base_path)", to: "publish_intents#show"
  #   delete "/publish-intent(/*base_path)", to: "publish_intents#destroy"
  end

  get '/healthcheck', :to => proc { [200, {}, ['OK']] }
end
