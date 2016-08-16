Rails.application.routes.draw do

  # INSTITUTION ROUTES
  institution_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)/
  resources :institutions, format: [:json, :html], param: :institution_identifier, institution_identifier: institution_ptrn
  resources :institutions, only: [:index], format: :json, param: :institution_identifier, path: 'api/v2/institutions'

  # INTELLECTUAL OBJECT ROUTES
  object_ptrn = /(\w+)*(\.edu|\.com|\.org)(\%|\/)[\w\-\.]+/
  resources :intellectual_objects, only: [:show, :edit, :update, :destroy], format: [:json, :html], param: :intellectual_object_identifier, intellectual_object_identifier: object_ptrn, path: 'objects'
  put 'objects/:intellectual_object_identifier/restore', to: 'intellectual_objects#restore', format: [:json, :html], intellectual_object_identifier: object_ptrn, as: :intellectual_object_restore
  put 'objects/:intellectual_object_identifier/dpn', to: 'intellectual_objects#send_to_dpn', format: [:json, :html], intellectual_object_identifier: object_ptrn, as: :intellectual_object_send_to_dpn
  get 'objects', to: 'intellectual_objects#index', format: [:json, :html]
  resources :intellectual_objects, only: [:show, :update, :destroy], format: :json, param: :intellectual_object_identifier, intellectual_object_identifier: object_ptrn, path: 'api/v2/objects'
  get 'api/v2/objects', to: 'intellectual_objects#index', format: [:json, :html]
  post 'api/v2/objects/:institution_identifier', to: 'intellectual_objects#create', format: :json, institution_identifier: institution_ptrn
  resources :intellectual_objects, only: [:index], format: :json, path: 'member-api/v1/objects'

  # GENERIC FILE ROUTES
  file_ptrn = /(\w+)*(\.edu|\.com|\.org)(\%2[Ff]|\/)+[\w\-\/\.]+(\%2[fF]|\/)+[\w\-\/\.\%]+/
  resources :generic_files, only: [:show, :update, :destroy], format: [:json, :html], param: :generic_file_identifier, generic_file_identifier: file_ptrn, path: 'files'
  resources :generic_files, only: [:show, :update, :destroy], format: [:json, :html], param: :generic_file_identifier, path: 'api/v2/files'
  get 'files/:intellectual_object_identifier', to: 'generic_files#index', format: [:json, :html], intellectual_object_identifier: object_ptrn, as: :intellectual_object_files
  post 'files/:intellectual_object_identifier', to: 'generic_files#create', format: [:json, :html], intellectual_object_identifier: object_ptrn
  post 'files/:intellectual_object_identifier', to: 'generic_files#update', format: [:json, :html], intellectual_object_identifier: object_ptrn
  resources :generic_files, only: [:index, :create], format: [:json, :html], param: :intellectual_object_identifier, intellectual_object_identifier: object_ptrn, path: 'api/v2/files'

  # PREMIS EVENT ROUTES
  get 'events/:identifier', to: 'premis_events#index', format: [:json, :html], identifier: /[\/\-\%\w\.]*/, as: :events
  post 'events/:identifier', to: 'premis_events#create', format: [:json, :html], identifier: /[\/\-\%\w\.]*/
  resources :premis_events, only: [:create], format: :json, param: :identifier, path: 'api/v2/events'

  # WORK ITEM ROUTES
  resources :work_items, only: [:index, :create, :show, :update], path: 'items'
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


  # CATALOG ROUTES
  post 'search/', to: 'catalog#search', format: [:json, :html], as: :search
  get 'search/', to: 'catalog#search', format: [:json, :html]
  get 'api/v2/search', to: 'catalog#search', format: [:json, :html], as: :api_search

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
