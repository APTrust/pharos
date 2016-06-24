Rails.application.routes.draw do

  # INSTITUTION ROUTES
  institution_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)/
  resources :institutions, format: [:json, :html], param: :institution_identifier
  resources :institutions, only: [:index], format: :json, param: :institution_identifier, path: 'api/v1/institutions'

  # INTELLECTUAL OBJECT ROUTES
  object_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)[\w\-\.]+/
  resources :intellectual_objects, only: [:index, :create], param: :institution_identifier, format: [:json, :html], path: 'objects'
  resources :intellectual_objects, only: [:show, :edit, :update, :destroy], format: [:json, :html], param: :intellectual_object_identifier, path: 'objects'
  resources :intellectual_objects, only: [:show, :update, :destroy], format: :json, param: :intellectual_object_identifier, path: 'api/v1/objects'
  resources :intellectual_objects, only: [:index], format: :json, param: :institution_identifier, path: 'member-api/v1/objects'

  # GENERIC FILE ROUTES
  file_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)\/[\w\-\.\/]+/
  resources :generic_files, only: [:index, :create], format: [:json, :html], param: :intellectual_object_identifier, path: 'files'
  resources :generic_files, only: [:show, :update, :destroy], format: [:json, :html], param: :generic_file_identifier, path: 'files'
  resources :generic_files, only: [:index, :create], format: [:json, :html], param: :intellectual_object_identifier, path: 'api/v1/files'
  resources :generic_files, only: [:show, :update, :destroy], format: [:json, :html], param: :generic_file_identifier, path: 'api/v1/files'

  # PREMIS EVENT ROUTES
  resources :premis_events, only: [:index, :create], format: [:json, :html], param: :identifier, path: 'events'
  resources :premis_events, only: [:create], format: :json, param: :identifier, path: 'api/v1/events'

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
