Rails.application.routes.draw do

  institution_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)/
  resources :institutions, param: :identifier, identifier: institution_ptrn do
    resources :intellectual_objects, only: [:index, :create], path: 'objects'
    resources :premis_events, only: [:index]
  end

  object_identifier_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)\/[\w\-\.]+/
  resources :intellectual_objects, format: [:json, :html], param: :identifier, identifier: object_identifier_ptrn, path: 'objects' do
    resources :generic_files, only: [:index, :create], path: 'files'
    resources :premis_events, only: [:index, :create]
  end

  get '/api/v1/objects/:esc_identifier', to: 'intellectual_objects#show', format: 'json', esc_identifier: /[^\/]*/, as: :object_by_identifier
  put  '/api/v1/objects/:esc_identifier', to: 'intellectual_objects#update', identifier: /[^\/]*/, as: :object_update_by_identifier, defaults: {format: 'json'}
  get '/member-api/v1/objects/', to: 'intellectual_objects#index', format: 'json'

  file_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org)\/[\w\-\.\/]+/
  resources :generic_files, param: :identifier, identifier: file_ptrn, path: 'files' do
    resources :premis_events, only: [:index, :create]
  end

  resources :work_items, path: 'items'

  resources :work_items, path: '/api/v1/items'

  get '/api/v1/items/:etag/:name/:bag_date', to: 'work_items#show', as: :work_item_by_etag, name: /[^\/]*/, bag_date: /[^\/]*/
  put '/api/v1/items/:etag/:name/:bag_date', to: 'work_items#update', format: 'json', as: :work_item_api_update_by_etag, name: /[^\/]*/, bag_date: /[^\/]*/

  post '/api/v1/items/delete_test_items', to: 'work_items#delete_test_items', format: 'json', as: :work_item_test_delete

  get '/member-api/v1/items/', to: 'work_items#api_index', format: 'json'

  devise_for :users

  resources :users do
    patch 'update_password', on: :collection
    get 'edit_password', on: :member
    patch 'generate_api_key', on: :member
  end

  get 'users/:id/admin_password_reset', to: 'users#admin_password_reset', as: :admin_password_reset_user

  # OTHER ----------------------------------------------------------------------

  get '/api/v1/institutions/:institution_identifier', to: 'institutions#show', format: 'json', as: :institution_api_show, institution_identifier: institution_ptrn

  post '/api/v1/objects/include_nested', to: 'intellectual_objects#create_from_json', format: 'json'
  post '/api/v1/objects/:identifier/files/save_batch', to: 'generic_files#save_batch', format: 'json', identifier: /[^\/]*/, as: :generic_files_save_batch
  post '/api/v1/objects/:identifier/files(.:format)', to: 'generic_files#create', format: 'json', identifier: /[^\/]*/
  get  '/api/v1/objects/:identifier/files(.:format)', to: 'generic_files#index', format: 'json', identifier: /[^\/]*/

  post '/api/v1/objects/:identifier/events(.:format)', to: 'events#create', format: 'json', identifier: /[^\/]*/, as: 'events_by_object_identifier'


  get  '/api/v1/file_summary/:identifier', to: 'generic_files#file_summary', format: 'json', identifier: /[^\/]*/, as: 'file_summary'
  get  '/api/v1/files/not_checked_since', to: 'generic_files#not_checked_since', format: 'json', generic_file_identifier: /[^\/]*/, as: 'files_not_checked_since'
  get  '/api/v1/files/:generic_file_identifier', to: 'generic_files#show', format: 'json', generic_file_identifier: /[^\/]*/, as: 'file_by_identifier'
  put  '/api/v1/files/:generic_file_identifier', to: 'generic_files#update', format: 'json', generic_file_identifier: /[^\/]*/, as: 'file_update_by_identifier'



  # The pattern for generic_file_identifier is tricky, because we do not want it to
  # conflict with /files/:generic_file_id/events. The pattern is: non-slash characters,
  # followed by a period, followed by more non-slash characters. For example,
  # virginia.edu.bagname/data/file.txt will not conflict with urn:mace:aptrust:12345
  post '/api/v1/files/:generic_file_identifier/events(.:format)', to: 'events#create', format: 'json', generic_file_identifier: /[^\/]*\.[^\/]*/, as: 'events_by_file_identifier'

  #
  # End of API routes
  # ----------------------------------------------------------------------

  authenticated :user do
    root to: 'institutions#show', as: 'authenticated_root'
  end

  root :to => 'institutions#show'
end
