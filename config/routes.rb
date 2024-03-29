Rails.application.routes.draw do

  # INSTITUTION ROUTES
  institution_ptrn = /(?:[a-zA-Z0-9\-_]+)(?:\.[a-zA-Z]+)+/
  resources :institutions, format: [:json, :html], param: :institution_identifier, institution_identifier: institution_ptrn
  resources :institutions, only: [:index], format: :json, param: :institution_identifier, institution_identifier: institution_ptrn, path: 'api/v2/institutions'
  get ':institution_identifier/single_snapshot', to: 'institutions#single_snapshot', format: [:html, :json], institution_identifier: institution_ptrn, as: :institution_snapshot
  get 'api/v2/:institution_identifier/single_snapshot', to: 'institutions#single_snapshot', format: [:html, :json], institution_identifier: institution_ptrn, as: :api_institution_snapshot
  get '/group_snapshot', to: 'institutions#group_snapshot', format: [:html, :json], as: :group_snapshot
  get 'api/v2/group_snapshot', to: 'institutions#group_snapshot', format: [:html, :json], as: :api_group_snapshot
  get '/:institution_identifier/deactivate', to: 'institutions#deactivate', as: :deactivate_institution, institution_identifier: institution_ptrn
  get '/:institution_identifier/reactivate', to: 'institutions#reactivate', as: :reactivate_institution, institution_identifier: institution_ptrn
  get '/:institution_identifier/enable_otp', to: 'institutions#enable_otp', as: :enable_otp_institution, format: [:html, :json], institution_identifier: institution_ptrn
  get '/:institution_identifier/disable_otp', to: 'institutions#disable_otp', as: :disable_otp_institution, format: [:html, :json], institution_identifier: institution_ptrn
  post 'api/v2/:institution_identifier/trigger_bulk_delete', to: 'institutions#trigger_bulk_delete', as: :api_bulk_deletion, format: :json, institution_identifier: institution_ptrn
  get '/:institution_identifier/confirm_bulk_delete_institution', to: 'institutions#partial_confirmation_bulk_delete', as: :bulk_deletion_institutional_confirmation, format: [:html, :json], institution_identifier: institution_ptrn
  post 'api/v2/:institution_identifier/confirm_bulk_delete_institution', to: 'institutions#partial_confirmation_bulk_delete', as: :api_bulk_deletion_institutional_confirmation, format: :json, institution_identifier: institution_ptrn
  get '/:institution_identifier/confirm_bulk_delete_admin', to: 'institutions#final_confirmation_bulk_delete', as: :bulk_deletion_admin_confirmation, format: [:html, :json], institution_identifier: institution_ptrn
  post 'api/v2/:institution_identifier/confirm_bulk_delete_admin', to: 'institutions#final_confirmation_bulk_delete', as: :api_bulk_deletion_admin_confirmation, format: :json, institution_identifier: institution_ptrn
  get '/:institution_identifier/finished_bulk_delete', to: 'institutions#finished_bulk_delete', as: :bulk_deletion_finished, format: [:html, :json], institution_identifier: institution_ptrn
  post 'api/v2/:institution_identifier/finished_bulk_delete', to: 'institutions#finished_bulk_delete', as: :api_bulk_deletion_finished, format: :json, institution_identifier: institution_ptrn
  get '/notifications/deletion', to: 'institutions#deletion_notifications', as: :institution_deletion_notifications, format: [:html, :json]
  get 'api/v2/notifications/deletion', to: 'institutions#deletion_notifications', as: :api_institution_deletion_notifications, format: [:html, :json]
  get '/:institution_identifier/mass_forced_password_update', to: 'institutions#mass_forced_password_update', as: :mass_forced_password_update, format: [:html, :json], institution_identifier: institution_ptrn
  get 'api/v2/:institution_identifier/mass_forced_password_update', to: 'institutions#mass_forced_password_update', as: :api_mass_forced_password_update, format: [:html, :json], institution_identifier: institution_ptrn

  # Admin URL for monthly deposit report
  get 'api/v2/deposit_summary', to: 'institutions#deposit_summary', as: :institution_deposit_summary, format: [:json]


  # INTELLECTUAL OBJECT ROUTES
  object_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org|\.museum)(\%|\/)[\w\-\.\%\?\=\(\)\:\#\[\]\!\$\&\'\*\+\,\;\_\~\ \p{L}]+/
  resources :intellectual_objects, only: [:show, :edit, :update, :destroy], format: [:json, :html], param: :intellectual_object_identifier, intellectual_object_identifier: object_ptrn, path: 'objects'
  get 'objects/:intellectual_object_identifier/restore', to: 'intellectual_objects#restore', format: [:json, :html], intellectual_object_identifier: object_ptrn, as: :intellectual_object_restore
  get 'objects', to: 'intellectual_objects#index', format: [:json, :html]
  get 'objects/:institution_identifier', to: 'intellectual_objects#index', format: [:json, :html], institution_identifier: institution_ptrn, as: :intellectual_objects
  resources :intellectual_objects, only: [:show, :update, :destroy], format: :json, param: :intellectual_object_identifier, intellectual_object_identifier: object_ptrn, path: 'api/v2/objects'
  get 'api/v2/objects/:institution_identifier', to: 'intellectual_objects#index', format: [:json, :html], institution_identifier: institution_ptrn
  get 'api/v2/objects', to: 'intellectual_objects#index', format: [:json, :html]
  post 'api/v2/objects/:institution_identifier', to: 'intellectual_objects#create', format: :json, institution_identifier: institution_ptrn
  get 'member-api/v2/objects/:institution_identifier', to: 'intellectual_objects#index', format: [:json, :html], institution_identifier: institution_ptrn
  get 'member-api/v2/objects/', to: 'intellectual_objects#index', format: [:json, :html]
  get 'member-api/v2/objects/:intellectual_object_identifier/restore', to: 'intellectual_objects#restore', format: :json, intellectual_object_identifier: object_ptrn
  put 'api/v2/objects/:intellectual_object_identifier/restore', to: 'intellectual_objects#restore', format: :json, intellectual_object_identifier: object_ptrn
  delete 'api/v2/objects/:intellectual_object_identifier/delete', to: 'intellectual_objects#destroy', format: :json, intellectual_object_identifier: object_ptrn
  delete 'objects/:intellectual_object_identifier/confirm_delete', to: 'intellectual_objects#confirm_destroy', format: [:html, :json], intellectual_object_identifier: object_ptrn, as: :object_confirm_destroy
  delete 'api/v2/objects/:intellectual_object_identifier/confirm_delete', to: 'intellectual_objects#confirm_destroy', format: :json, intellectual_object_identifier: object_ptrn, as: :api_object_confirm_destroy
  get 'objects/:intellectual_object_identifier/confirm_delete', to: 'intellectual_objects#confirm_destroy', format: [:html, :json], intellectual_object_identifier: object_ptrn, as: :get_object_confirm_destroy
  get 'api/v2/objects/:intellectual_object_identifier/confirm_delete', to: 'intellectual_objects#confirm_destroy', format: :json, intellectual_object_identifier: object_ptrn, as: :get_api_object_confirm_destroy
  get 'objects/:intellectual_object_identifier/finish_delete', to: 'intellectual_objects#finished_destroy', format: [:html, :json], intellectual_object_identifier: object_ptrn, as: :get_object_finish_destroy
  get 'api/v2/objects/:intellectual_object_identifier/finish_delete', to: 'intellectual_objects#finished_destroy', format: :json, intellectual_object_identifier: object_ptrn, as: :get_api_object_finish_destroy

  # GENERIC FILE ROUTES
  file_ptrn = /(\w+\.)*\w+(\.edu|\.com|\.org|\.museum)(\%2[Ff]|\/)+[\w\-\/\.\%\?\=\(\)\:\#\[\]\!\$\&\'\*\+\,\;\_\~\ \p{L}]+(\%2[fF]|\/)+[\w\-\/\.\%\@\?\=\(\)\:\#\[\]\!\$\&\'\*\+\,\;\_\~\ \p{L}]+/

  resources :generic_files, only: [:index, :show, :update, :destroy], format: :html, defaults: { format: :html }, param: :generic_file_identifier, generic_file_identifier: file_ptrn, path: 'files'
  get 'files/:institution_identifier', to: 'generic_files#index', format: :html, institution_identifier: institution_ptrn, as: :institution_files
  get 'files/:intellectual_object_identifier', to: 'generic_files#index', format: :html, intellectual_object_identifier: object_ptrn, as: :intellectual_object_files
  resources :generic_files, only: [:index, :create], format: :json, param: :intellectual_object_identifier, intellectual_object_identifier: object_ptrn, path: 'api/v2/files'
  delete 'files/confirm_delete/:generic_file_identifier', to: 'generic_files#confirm_destroy', format: [:html, :json], generic_file_identifier: file_ptrn, as: :file_confirm_destroy
  get 'files/confirm_delete/:generic_file_identifier', to: 'generic_files#confirm_destroy', format: [:html, :json], generic_file_identifier: file_ptrn, as: :get_file_confirm_destroy
  get 'files/finish_delete/:generic_file_identifier', to: 'generic_files#finished_destroy', format: [:html, :json], generic_file_identifier: file_ptrn, as: :get_file_finish_destroy
  get 'files/restore/:generic_file_identifier', to: 'generic_files#restore', format: [:json, :html], generic_file_identifier: file_ptrn, as: :generic_file_restore

  get 'member-api/v2/files/:intellectual_object_identifier', to: 'generic_files#index', format: :json, intellectual_object_identifier: object_ptrn
  get 'member-api/v2/files/:institution_identifier', to: 'generic_files#index', format: :json, institution_identifier: institution_ptrn
  get 'member-api/v2/files/restore/:generic_file_identifier', to: 'generic_files#restore', format: :json, generic_file_identifier: file_ptrn

  resources :generic_files, only: [:show, :update, :destroy], format: [:json], defaults: { format: :json }, param: :generic_file_identifier, generic_file_identifier: file_ptrn, path: 'api/v2/files'
  get '/api/v2/files/:institution_identifier', to: 'generic_files#index', format: [:json], institution_identifier: institution_ptrn, as: :institution_files_api
  get '/api/v2/files/:intellectual_object_identifier', to: 'generic_files#index', format: [:json], intellectual_object_identifier: object_ptrn, as: :intellectual_object_files_api
  get '/api/v2/files/', to: 'generic_files#index', format: [:json], as: :generic_files_admin_list
  post '/api/v2/files/:intellectual_object_id/create_batch', to: 'generic_files#create_batch', format: :json
  post '/api/v2/files/:intellectual_object_identifier', to: 'generic_files#create', format: :json, intellectual_object_identifier: object_ptrn
  put '/api/v2/files/:intellectual_object_identifier', to: 'generic_files#update', format: :json, intellectual_object_identifier: object_ptrn
  delete 'api/v2/files/confirm_delete/:generic_file_identifier', to: 'generic_files#confirm_destroy', format: [:html, :json], generic_file_identifier: file_ptrn, as: :api_file_confirm_destroy
  get 'api/v2/files/confirm_delete/:generic_file_identifier', to: 'generic_files#confirm_destroy', format: [:html, :json], generic_file_identifier: file_ptrn, as: :get_api_file_confirm_destroy
  get 'api/v2/files/finish_delete/:generic_file_identifier', to: 'generic_files#finished_destroy', format: [:html, :json], generic_file_identifier: file_ptrn, as: :get_api_file_finish_destroy
  put 'api/v2/files/restore/:generic_file_identifier', to: 'generic_files#restore', format: :json, generic_file_identifier: file_ptrn


  # INSTITUTIONS (API)
  # resources :institutions doesn't like this route for #show, because it interprets .edu/.org/.com as an 'unknown format'
  get 'api/v2/institutions/:institution_identifier', to: 'institutions#show', format: [:json], institution_identifier: institution_ptrn

  # PREMIS EVENT ROUTES
  uuid_pattern = /([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}){1}/
  get '/api/v2/events/:identifier', to: 'premis_events#show', format: [:json], identifier: uuid_pattern
  get 'events/:file_identifier', to: 'premis_events#index', format: [:json, :html], file_identifier: file_ptrn, as: :generic_file_events
  get 'events/:object_identifier', to: 'premis_events#index', format: [:json, :html], object_identifier: object_ptrn, as: :intellectual_object_events
  get 'events/:institution_identifier', to: 'premis_events#index', format: [:json, :html], institution_identifier: institution_ptrn, as: :institution_events
  get 'events/:id', to: 'premis_events#show', format: [:json, :html], as: :premis_event
  get '/api/v2/events', to: 'premis_events#index', format: [:json, :html]
  post '/api/v2/events', to: 'premis_events#create', format: :json
  get '/api/v2/events/:id', to: 'premis_events#show', format: [:json, :html]
  get 'member-api/v2/events/:file_identifier', to: 'premis_events#index', format: :json, file_identifier: file_ptrn
  get 'member-api/v2/events/:object_identifier', to: 'premis_events#index', format: :json, object_identifier: object_ptrn
  get 'member-api/v2/events/:institution_identifier', to: 'premis_events#index', format: :json, institution_identifier: institution_ptrn
  get 'notifications/failed_fixity', to: 'premis_events#notify_of_failed_fixity', format: :json
  get '/api/v2/notifications/failed_fixity', to: 'premis_events#notify_of_failed_fixity', format: :json

  # WORK ITEM ROUTES
  resources :work_items, only: [:index, :create, :show, :update, :edit], format: [:html, :json], path: 'items'
  put 'items/', to: 'work_items#update', format: :json
  resources :work_items, path: '/api/v2/items'
  resources :work_items, only: [:index], path: 'member-api/v2/items', format: [:json, :html]
  get '/api/v2/items/:etag/:name/:bag_date', to: 'work_items#show', as: :work_item_by_etag, name: /[^\/]*/, bag_date: /[^\/]*/
  put '/api/v2/items/:etag/:name/:bag_date', to: 'work_items#update', format: 'json', as: :work_item_api_update_by_etag, name: /[^\/]*/, bag_date: /[^\/]*/
  get 'items/items_for_restore', to: 'work_items#items_for_restore', format: :json
  get 'items/items_for_delete', to: 'work_items#items_for_delete', format: :json
  get 'items/ingested_since', to: 'work_items#ingested_since', format: :json
  get 'items/set_restoration_status', to: 'work_items#set_restoration_status', format: :json
  get 'api/v2/items/search', to: 'work_items#api_search', format: :json
  get 'items/:id/requeue', to: 'work_items#requeue', format: [:json, :html], as: :requeue_work_item
  get 'notifications/successful_restoration', to: 'work_items#notify_of_successful_restoration', format: :json
  get '/api/v2/notifications/successful_restoration', to: 'work_items#notify_of_successful_restoration', format: :json
  get 'notifications/spot_test_restoration/:id', to: 'work_items#spot_test_restoration', format: :json
  get '/api/v2/notifications/spot_test_restoration/:id', to: 'work_items#spot_test_restoration', format: :json

  # WORK ITEM STATE ROUTES
  #resources :work_item_states, path: 'item_state', only: [:show, :update, :create], format: :json, param: :work_item_id
  #resources :work_item_states, path: '/api/v2/item_state', only: [:show, :update, :create], format: :json, param: :work_item_id
  post '/api/v2/item_state', to: 'work_item_states#create', format: :json
  put '/api/v2/item_state/:id', to: 'work_item_states#update', format: :json
  get '/api/v2/item_state/:id', to: 'work_item_states#show', format: :json

  # CHECKSUM ROUTES
  get '/api/v2/checksums', to: 'checksums#index', format: :json
  get '/api/v2/checksums/:id', to: 'checksums#show', format: :json
  post '/api/v2/checksums/:generic_file_identifier', to: 'checksums#create', format: :json, generic_file_identifier: /.*/

  # CATALOG ROUTES
  post 'search/', to: 'catalog#search', format: [:json, :html], as: :search
  get 'search/', to: 'catalog#search', format: [:json, :html]
  get 'api/v2/search', to: 'catalog#search', format: [:json, :html], as: :api_search
  get 'feed', to: 'catalog#feed', format: :rss, as: :rss_feed

  # REPORT ROUTES
  get 'reports/:identifier', to: 'reports#index', format: [:json, :html], as: :reports, identifier: institution_ptrn
  get 'reports/overview/:identifier', to: 'reports#overview', format: [:json, :html, :pdf], as: :institution_overview, identifier: institution_ptrn
  get 'reports/general/:identifier', to: 'reports#general', format: [:json, :html, :pdf], as: :institution_general_report, identifier: institution_ptrn
  get 'reports/cost/:identifier', to: 'reports#cost', format: [:json, :html, :pdf], as: :institution_cost_report, identifier: institution_ptrn
  get 'reports/subscribers/:identifier', to: 'reports#subscribers', format: [:json, :html, :pdf], as: :institution_subscribers_report, identifier: institution_ptrn
  get 'reports/timeline/:identifier', to: 'reports#timeline', format: [:json, :html, :pdf], as: :institution_timeline_report, identifier: institution_ptrn
  get 'reports/mimetype/:identifier', to: 'reports#mimetype', format: [:json, :html, :pdf], as: :institution_mimetype_report, identifier: institution_ptrn
  get 'reports/institution_breakdown', to: 'reports#institution_breakdown', format: [:json, :html, :pdf], as: :institution_breakdown
  get 'reports/object_report/:intellectual_object_identifier', to: 'reports#object_report', format: [:json, :html], as: :object_report, intellectual_object_identifier: object_ptrn

  # ALERT ROUTES
  get 'alerts/', to: 'alerts#index', format: [:json, :html], as: :alerts
  get 'alerts/summary', to: 'alerts#summary', format: [:json, :html], as: :alerts_summary

  # EMAIL ROUTES
  resources :emails, path: 'email_logs', only: [:index, :show], format: [:json]

  # SNAPSHOT ROUTES
  resources :snapshots, path: 'snapshots', only: [:index, :show], format: [:json, :html]

  # BULK DELETE JOB ROUTES
  resources :bulk_delete_jobs, path: 'bulk_delete_jobs', only: [:index, :show], format: [:json, :html]
  resources :bulk_delete_jobs, path: 'api/v2/bulk_delete_jobs', only: [:index, :show], format: :json

  # USER ROUTES
  devise_for :users,
  pathnames: {
      verify_authy: '/verify-token',
      enable_authy: '/enable-authy',
      verify_authy_installation: '/verify-installation'
  }

  resources :users do
    patch 'update_password', on: :collection
    get 'edit_password', on: :member
    patch 'generate_api_key', on: :member
  end
  get 'users/:id/admin_password_reset', to: 'users#admin_password_reset', as: :admin_password_reset_user
  get 'users/:id/forced_password_update', to: 'users#forced_password_update', as: :user_forced_password_update
  get 'users/:id/deactivate', to: 'users#deactivate', as: :deactivate_user
  get 'users/:id/reactivate', to: 'users#reactivate', as: :reactivate_user
  get '/vacuum', to: 'users#vacuum', format: [:json, :html], as: :vacuum
  get '/api/v2/vacuum', to: 'users#vacuum', format: [:json, :html], as: :api_vacuum
  get '/notifications/stale_users', to: 'users#stale_user_notification', format: [:json, :html], as: :stale_users
  get '/api/v2/notifications/stale_users', to: 'users#stale_user_notification', format: [:json, :html], as: :api_stale_users
  get '/account_confirmations', to: 'users#account_confirmations', format: [:json, :html], as: :account_confirmations
  get '/api/v2/account_confirmations', to: 'users#account_confirmations', format: [:json, :html], as: :api_account_confirmations
  get '/users/:id/individual_account_confirmation', to: 'users#indiv_confirmation_email', format: [:json, :html], as: :indiv_confirmation_email
  get '/api/v2/users/:id/individual_account_confirmation', to: 'users#indiv_confirmation_email', format: [:json, :html], as: :api_indiv_confirmation_email
  get '/users/:id/confirm_account', to: 'users#confirm_account', format: [:json, :html], as: :confirm_account
  get '/api/v2/users/:id/confirm_account', to: 'users#confirm_account', format: [:json, :html], as: :api_confirm_account
  get 'users/:id/enable_otp', to: 'users#enable_otp', as: :users_enable_otp
  get 'users/:id/disable_otp', to: 'users#disable_otp', as: :users_disable_otp
  get 'users/:id/register_authy', to: 'users#register_authy_user', as: :users_register_for_authy
  get 'users/:id/change_authy_phone_number', to: 'users#change_authy_phone_number', as: :user_authy_number
  get 'users/:id/verify_twofa', to: 'users#verify_twofa', as: :users_verify_twofa
  get 'users/:id/backup_codes', to: 'users#generate_backup_codes', as: :backup_codes
  get 'users/:id/two_factor_text_link', to: 'users#two_factor_text_link', as: :twofa_text
  get 'users/:id/verify_email', to: 'users#verify_email', as: :email_verification
  get 'users/:id/email_confirmation', to: 'users#email_confirmation', as: :email_confirmation

  resources :verifications, only: [:edit, :update]
  get 'verifications/login', to: 'verifications#login', as: :verification_login
  get 'verifications/enter_backup/:id', to: 'verifications#enter_backup', as: :enter_backup_verification
  put 'verifications/check_backup/:id', to: 'verifications#check_backup', as: :check_backup_verification

  #get '/verification_callback', to: 'application#callback', as: :verification_callback

  authenticated :user do
    root to: 'institutions#show', as: 'authenticated_root'
  end

  root :to => 'institutions#show'

  match '*path', to: 'application#catch_404', via: :all
end
