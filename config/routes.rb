Rails.application.routes.draw do

  # INSTITUTION ROUTES
  institution_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)/
  resources :institutions, format: [:json, :html], param: :institution_identifier, institution_identifier: institution_ptrn
  resources :institutions, only: [:index], format: :json, param: :institution_identifier, path: 'api/v2/institutions'

  # INTELLECTUAL OBJECT ROUTES
  object_ptrn = /(\w+)*(\.edu|\.com|\.org)(\%|\/)[\w\-\.]+/
  resources :intellectual_objects, only: [:show, :edit, :update, :destroy], format: [:json, :html], param: :intellectual_object_identifier, intellectual_object_identifier: object_ptrn, path: 'objects'
  get 'objects/:intellectual_object_identifier/restore', to: 'intellectual_objects#restore', format: [:json, :html], intellectual_object_identifier: object_ptrn, as: :intellectual_object_restore
  get 'objects/:intellectual_object_identifier/dpn', to: 'intellectual_objects#send_to_dpn', format: [:json, :html], intellectual_object_identifier: object_ptrn, as: :intellectual_object_send_to_dpn
  get 'objects', to: 'intellectual_objects#index', format: [:json, :html]
  get 'objects/:institution_identifier', to: 'intellectual_objects#index', format: [:json, :html], institution_identifier: institution_ptrn, as: :intellectual_objects
  resources :intellectual_objects, only: [:show, :update, :destroy], format: :json, param: :intellectual_object_identifier, intellectual_object_identifier: object_ptrn, path: 'api/v2/objects'
  get 'api/v2/objects/:institution_identifier', to: 'intellectual_objects#index', format: [:json, :html], institution_identifier: institution_ptrn
  post 'api/v2/objects/:institution_identifier', to: 'intellectual_objects#create', format: :json, institution_identifier: institution_ptrn
  #resources :intellectual_objects, only: [:index], format: :json, path: 'member-api/v2/objects'
  get 'member-api/v2/objects/:institution_identifier', to: 'intellectual_objects#index', format: [:json, :html], institution_identifier: institution_ptrn
  get 'member-api/v2/objects/:intellectual_object_identifier/restore', to: 'intellectual_objects#restore', format: :json, intellectual_object_identifier: object_ptrn
  put 'member-api/v2/objects/:intellectual_object_identifier/dpn', to: 'intellectual_objects#send_to_dpn', format: :json, intellectual_object_identifier: object_ptrn
  put 'api/v2/objects/:intellectual_object_identifier/dpn', to: 'intellectual_objects#send_to_dpn', format: :json, intellectual_object_identifier: object_ptrn

  # GENERIC FILE ROUTES
  file_ptrn = /(\w+)*(\.edu|\.com|\.org)(\%2[Ff]|\/)+[\w\-\/\.]+(\%2[fF]|\/)+[\w\-\/\.\%]+/
  resources :generic_files, only: [:show, :update, :destroy], format: [:json, :html], param: :generic_file_identifier, generic_file_identifier: file_ptrn, path: 'files'
  resources :generic_files, only: [:show, :update, :destroy], format: [:json, :html], param: :generic_file_identifier, path: 'api/v2/files'
  get 'files/:intellectual_object_identifier', to: 'generic_files#index', format: [:json, :html], intellectual_object_identifier: object_ptrn, as: :intellectual_object_files
  get 'files/:institution_identifier', to: 'generic_files#index', format: [:json, :html], institution_identifier: institution_ptrn
  post '/api/v2/files/:intellectual_object_id/create_batch', to: 'generic_files#create_batch', format: :json
  post 'files/:intellectual_object_identifier', to: 'generic_files#create', format: [:json, :html], intellectual_object_identifier: object_ptrn
  post 'files/:intellectual_object_identifier', to: 'generic_files#update', format: [:json, :html], intellectual_object_identifier: object_ptrn
  resources :generic_files, only: [:index, :create], format: [:json, :html], param: :intellectual_object_identifier, intellectual_object_identifier: object_ptrn, path: 'api/v2/files'

  # INSTITUTIONS (API)
  # resources :institutions doesn't like this route for #show, because it interprets .edu/.org/.com as an 'unknown format'
  get 'api/v2/institutions/:institution_identifier', to: 'institutions#show', format: [:json], institution_identifier: institution_ptrn

  # PREMIS EVENT ROUTES
  #get 'events/:identifier', to: 'premis_events#index', format: [:json, :html], identifier: /[\/\-\%\w\.]*/, as: :events
  get 'events/:file_identifier', to: 'premis_events#index', format: [:json, :html], file_identifier: file_ptrn, as: :generic_file_events
  get 'events/:object_identifier', to: 'premis_events#index', format: [:json, :html], object_identifier: object_ptrn, as: :intellectual_object_events
  get 'events/:institution_identifier', to: 'premis_events#index', format: [:json, :html], institution_identifier: institution_ptrn, as: :institution_events
  get '/api/v2/events', to: 'premis_events#index', format: [:json, :html]
  post '/api/v2/events', to: 'premis_events#create', format: :json

  # WORK ITEM ROUTES
  resources :work_items, only: [:index, :create, :show, :update], format: [:html, :json], path: 'items'
  put 'items/', to: 'work_items#update', format: :json
  resources :work_items, path: '/api/v2/items'
  resources :work_items, format: :json, only: [:index], path: 'member-api/v1/items'
  get '/api/v2/items/:etag/:name/:bag_date', to: 'work_items#show', as: :work_item_by_etag, name: /[^\/]*/, bag_date: /[^\/]*/
  put '/api/v2/items/:etag/:name/:bag_date', to: 'work_items#update', format: 'json', as: :work_item_api_update_by_etag, name: /[^\/]*/, bag_date: /[^\/]*/
  get 'items/items_for_dpn', to: 'work_items#items_for_dpn', format: :json
  get 'items/items_for_restore', to: 'work_items#items_for_restore', format: :json
  get 'items/items_for_delete', to: 'work_items#items_for_delete', format: :json
  get 'items/ingested_since', to: 'work_items#ingested_since', format: :json
  get 'items/set_restoration_status', to: 'work_items#set_restoration_status', format: :json
  get 'api/v2/items/search', to: 'work_items#api_search', format: :json

  # WORK ITEM STATE ROUTES
  #resources :work_item_states, path: 'item_state', only: [:show, :update, :create], format: :json, param: :work_item_id
  #resources :work_item_states, path: '/api/v2/item_state', only: [:show, :update, :create], format: :json, param: :work_item_id
  post '/api/v2/item_state', to: 'work_item_states#create', format: :json
  put '/api/v2/item_state/:work_item_id', to: 'work_item_states#update', format: :json
  get '/api/v2/item_state/:work_item_id', to: 'work_item_states#show', format: :json
  get '/api/v2/item_state/:id', to: 'work_item_states#show', format: :json

  # CHECKSUM ROUTES
  get '/api/v2/checksums', to: 'checksums#index', format: :json
  post '/api/v2/checksums/:generic_file_identifier', to: 'checksums#create', format: :json, generic_file_identifier: file_ptrn

  # CATALOG ROUTES
  post 'search/', to: 'catalog#search', format: [:json, :html], as: :search
  get 'search/', to: 'catalog#search', format: [:json, :html]
  get 'api/v2/search', to: 'catalog#search', format: [:json, :html], as: :api_search
  get 'feed', to: 'catalog#feed', format: :rss, as: :rss_feed

  # REPORT ROUTES
  get 'reports/:identifier', to: 'reports#index', format: [:json, :html], as: :reports, identifier: institution_ptrn

  # DPN Work Item Routes
  resources :dpn_work_items, path: 'api/v2/dpn_item', only: [:index, :create, :show, :update], format: :json

  # USER ROUTES
  devise_for :users

  resources :users do
    patch 'update_password', on: :collection
    get 'edit_password', on: :member
    patch 'generate_api_key', on: :member
  end
  get 'users/:id/admin_password_reset', to: 'users#admin_password_reset', as: :admin_password_reset_user

  authenticated :user do
    root to: 'institutions#show', as: 'authenticated_root'
  end

  root :to => 'institutions#show'
end
