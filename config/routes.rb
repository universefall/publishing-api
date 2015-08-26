Rails.application.routes.draw do
  scope format: false do |r|
    put "/draft-content(/*base_path)", to: "content_items#put_draft_content_item"
    put "/content(/*base_path)", to: "content_items#put_live_content_item"

    put "/publish-intent(/*base_path)", to: "publish_intents#create_or_update"
    get "/publish-intent(/*base_path)", to: "publish_intents#show"
    delete "/publish-intent(/*base_path)", to: "publish_intents#destroy"
  end

  post "/create-draft", to: "commands#process_command", command_name: "create_draft"
  post "/modify-draft", to: "commands#process_command", command_name: "modify_draft"
  post "/publish", to: "commands#process_command", command_name: "publish"
  post "/redraft", to: "commands#process_command", command_name: "redraft"
  get "/draft/:content_id", to: "queries#process_query", query_name: "get_draft"
  get "/live/:content_id", to: "queries#process_query", query_name: "get_live"

  get '/healthcheck', :to => proc { [200, {}, ['OK']] }
end
