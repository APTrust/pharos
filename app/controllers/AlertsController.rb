class AlertsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    authorize current_user, :alert_index?
    params[:since] = (DateTime.now - 24.hours) unless params[:since]
    get_index_lists(params[:since])
    respond_to do |format|
      format.json { render json: {  } }
      format.html { }
    end
  end

  def summary
    authorize current_user, :alert_summary?
    params[:since] = (DateTime.now - 24.hours) unless params[:since]
    get_summary_counts(params[:since])
    respond_to do |format|
      format.json { render json: {  } }
      format.html { }
    end
  end

  private

  def get_summary_counts(datetime)
    @failed_fixity_count = PremisEvent.failed_fixity_check_count(datetime)
    @failed_ingest_count = WorkItem.failed_action_count(datetime, Pharos::Application::PHAROS_ACTIONS['ingest'])
    @failed_restoration_count = WorkItem.failed_action_count(datetime, Pharos::Application::PHAROS_ACTIONS['restore'])
    @failed_deletion_count = WorkItem.failed_action_count(datetime, Pharos::Application::PHAROS_ACTIONS['delete'])
    @failed_dpn_ingest_count = WorkItem.failed_action_count(datetime, Pharos::Application::PHAROS_ACTIONS['dpn'])
    @failed_dpn_replication_count
    @stalled_work_item_count = WorkItem.stalled_items_count
  end

  def get_index_lists(datetime)
    @failed_fixity_checks = PremisEvent.failed_fixity_checks(datetime)
    @failed_ingests = WorkItem.failed_action(datetime, Pharos::Application::PHAROS_ACTIONS['ingest'])
    @failed_restorations = WorkItem.failed_action(datetime, Pharos::Application::PHAROS_ACTIONS['restore'])
    @failed_deletions = WorkItem.failed_action(datetime, Pharos::Application::PHAROS_ACTIONS['delete'])
    @failed_dpn_ingests = WorkItem.failed_action(datetime, Pharos::Application::PHAROS_ACTIONS['dpn'])
    @failed_dpn_replications
    @stalled_work_items = WorkItem.stalled_items
  end

  # The summary method will return the following counts:
  #
  # x failed fixity checks (from PremisEvents) DONE
  # x failed ingests (from WorkItems) DONE
  # x failed restorations (from WorkItems) DONE
  # x failed deletions (from WorkItems) DONE
  # x failed DPN ingests (from WorkItems) DONE
  # x failed DPN replications (from DPN Work Items)
  # x stalled work items (from WorkItems)
  #
  # Stalled work items are any WorkItems where queued_at is more than 12 hours ago and status is not Success,
  # Failed, or Cancelled. Stalled WorkItems will ignore the "since" parameter and always use 12 hours as its timeframe.
  #
  # The index method of this controller will return actual lists of these failed items, similar to the WorkItems list page.
  # It can take a second param, "type" or something like that, to indicate whether to list stalled items, failed fixities,
  # failed work items or failed DPN items. It might be easiest to just provide a tabbed interface, with each tab adding the
  # require ?type=x to the URL.

end