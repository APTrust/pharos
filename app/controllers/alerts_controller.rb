class AlertsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    authorize current_user, :alert_index?
    params[:since] = (DateTime.now - 24.hours) unless params[:since]
    params[:type] = 'all' unless params[:type]
    respond_to do |format|
      format.json {
        get_index_lists(params[:since])
        render json: @alerts_list.to_json
      }
      format.html {
        params[:type] = 'all'
        get_index_lists(params[:since])
        render 'index'
      }
    end
  end

  def summary
    authorize current_user, :alert_summary?
    params[:since] = (DateTime.now - 24.hours) unless params[:since]
    get_summary_counts(params[:since])
    respond_to do |format|
      format.json { render json: @alerts_summary.to_json }
      format.html { }
    end
  end

  private

  def get_index_lists(datetime)
    @alerts_list = {}
    case params[:type]
      when 'fixity'
        @alerts_list[:failed_fixity_checks] = PremisEvent.failed_fixity_checks(datetime, current_user)
      when 'ingest'
        @alerts_list[:failed_ingests] = WorkItem.failed_action(datetime, Pharos::Application::PHAROS_ACTIONS['ingest'], current_user)
      when 'restore'
        @alerts_list[:failed_restorations] = WorkItem.failed_action(datetime, Pharos::Application::PHAROS_ACTIONS['restore'], current_user)
      when 'delete'
        @alerts_list[:failed_deletions] = WorkItem.failed_action(datetime, Pharos::Application::PHAROS_ACTIONS['delete'], current_user)
      when 'dpn_ingest'
        @alerts_list[:failed_dpn_ingests] = WorkItem.failed_action(datetime, Pharos::Application::PHAROS_ACTIONS['dpn'], current_user)
      when 'stalled_dpn'
        @alerts_list[:stalled_dpn_replications] = DpnWorkItem.stalled_dpn_replications if current_user.admin?
      when 'stalled_wi'
        @alerts_list[:stalled_work_items] = WorkItem.stalled_items(current_user)
      when 'all'
        @alerts_list[:failed_fixity_checks] = PremisEvent.failed_fixity_checks(datetime, current_user)
        @alerts_list[:failed_ingests] = WorkItem.failed_action(datetime, Pharos::Application::PHAROS_ACTIONS['ingest'], current_user)
        @alerts_list[:failed_restorations] = WorkItem.failed_action(datetime, Pharos::Application::PHAROS_ACTIONS['restore'], current_user)
        @alerts_list[:failed_deletions] = WorkItem.failed_action(datetime, Pharos::Application::PHAROS_ACTIONS['delete'], current_user)
        @alerts_list[:failed_dpn_ingests] = WorkItem.failed_action(datetime, Pharos::Application::PHAROS_ACTIONS['dpn'], current_user)
        @alerts_list[:stalled_dpn_replications] = DpnWorkItem.stalled_dpn_replications if current_user.admin?
        @alerts_list[:stalled_work_items] = WorkItem.stalled_items(current_user)
    end
  end

  def get_summary_counts(datetime)
    @alerts_summary = {}
    @alerts_summary[:failed_fixity_count] = PremisEvent.failed_fixity_check_count(datetime, current_user)
    @alerts_summary[:failed_ingest_count] = WorkItem.failed_action_count(datetime, Pharos::Application::PHAROS_ACTIONS['ingest'], current_user)
    @alerts_summary[:failed_restoration_count] = WorkItem.failed_action_count(datetime, Pharos::Application::PHAROS_ACTIONS['restore'], current_user)
    @alerts_summary[:failed_deletion_count] = WorkItem.failed_action_count(datetime, Pharos::Application::PHAROS_ACTIONS['delete'], current_user)
    @alerts_summary[:failed_dpn_ingest_count] = WorkItem.failed_action_count(datetime, Pharos::Application::PHAROS_ACTIONS['dpn'], current_user)
    @alerts_summary[:stalled_dpn_replication_count] = DpnWorkItem.stalled_dpn_replication_count if current_user.admin?
    @alerts_summary[:stalled_work_item_count] = WorkItem.stalled_items_count(current_user)
  end

end