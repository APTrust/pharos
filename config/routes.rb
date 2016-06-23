Rails.application.routes.draw do

  # INSTITUTION ROUTES
  institution_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)/
  resources :institutions, format: [:json, :html], param: :identifier, identifier: institution_ptrn do
    resources :intellectual_objects, only: [:index, :create], format: [:json, :html], path: 'objects'
  end
  resources :institutions, only: [:index], format: :json, param: :identifier, identifier: institution_ptrn, path: 'api/v1/institutions'

  # INTELLECTUAL OBJECT ROUTES
  object_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)\/[\w\-\.]+/
  resources :intellectual_objects, format: [:json, :html], param: :identifier, identifier: object_ptrn, path: 'objects'
  resources :intellectual_objects, format: :json, param: :identifier, identifier:  /[^\/]*/, path: 'api/v1/objects'
  resources :intellectual_objects, only: [:index], format: :json, param: :identifier, identifier:  institution_ptrn, path: 'member-api/v1/objects'
  get '/api/v1/objects/:esc_identifier', to: 'intellectual_objects#show', format: :json, esc_identifier: /[^\/]*/
  put '/api/v1/objects/:esc_identifier', to: 'intellectual_objects#update', format: :json, esc_identifier: /[^\/]*/

  # GENERIC FILE ROUTES
  file_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)\/[\w\-\.\/]+/
  resources :generic_files, only: [:index, :create], format: [:json, :html], param: :identifier, identifier: object_ptrn, path: 'files'
  resources :generic_files, only: [:show, :update, :destroy], format: [:json, :html], param: :identifier, identifier: file_ptrn, path: 'files'
  resources :generic_files, only: [:index, :create], format: [:json, :html], param: :identifier, identifier: /[^\/]*/, path: 'api/v1/files'
  resources :generic_files, only: [:show, :update, :destroy], format: [:json, :html], param: :identifier, identifier: /[^\/]*/, path: 'api/v1/files'
  get '/api/v1/files/esc_identifier', to: 'generic_files#index', format: 'json'

  # PREMIS EVENT ROUTES
  resources :premis_events, only: [:index], format: [:json, :html], param: :identifier, identifier: institution_ptrn, path: 'events'
  resources :premis_events, only: [:index, :create], format: [:json, :html], param: :identifier, identifier: object_ptrn, path: 'events'
  resources :premis_events, only: [:index, :create], format: [:json, :html], param: :identifier, identifier: file_ptrn, path: 'events', as: :institution_events
  resources :premis_events, only: [:create], format: :json, param: :identifier, identifier: /[^\/]*/, path: 'api/v1/events'

  # WORK ITEM ROUTES
  resources :work_items, only: [:index, :create, :show, :update], path: 'items'
  resources :work_items, path: '/api/v1/items'
  resources :work_items, format: :json, only: [:index], path: 'member-api/v1/items'
  get '/api/v1/items/:etag/:name/:bag_date', to: 'work_items#show', as: :work_item_by_etag, name: /[^\/]*/, bag_date: /[^\/]*/
  put '/api/v1/items/:etag/:name/:bag_date', to: 'work_items#update', format: 'json', as: :work_item_api_update_by_etag, name: /[^\/]*/, bag_date: /[^\/]*/

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
