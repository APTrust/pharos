require 'spec_helper'

describe 'Faceting' do

  before :all do
    Institution.destroy_all
    GenericFile.destroy_all
    IntellectualObject.destroy_all
  end

  describe 'Logged in as institutional_admin' do
    let(:file) { FactoryGirl.create(:generic_file) }
    let(:inst) { file.institution }
    let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_pid: inst.pid) }

    before do
      login_as user
    end

    describe 'Events list' do
      before do
        @event1 = file.add_event(type: 'Type 1', outcome: 'Outcome 1')
        @event2 = file.add_event(type: 'Type 2', outcome: 'Outcome 2')
        @event3 = file.add_event(type: 'Type 3', outcome: 'Outcome 3')
        file.save!
      end

      it 'facet by event type' do
        visit institution_events_path(inst)
        page.should have_css('#documents .document', count: 3)

        within('#facets .blacklight-event_type_ssim') do
          click_link 'Type 2'
        end

        page.should have_css('#documents .document', count: 1)

        page.should have_css('dd', text: @event2.outcome.first)
        page.should_not have_css('dd', text: @event1.outcome.first)
        page.should have_css('dd', text: @event2.type.first)
        page.should_not have_css('dd', text: @event1.type.first)
      end

      it 'facet by event outcome' do
        visit institution_events_path(inst)
        page.should have_css('#documents .document', count: 3)

        within('#facets .blacklight-event_outcome_ssim') do
          click_link 'Outcome 2'
        end

        page.should have_css('#documents .document', count: 1)

        page.should have_css('dd', text: @event2.outcome.first)
        page.should_not have_css('dd', text: @event1.outcome.first)
        page.should have_css('dd', text: @event2.type.first)
        page.should_not have_css('dd', text: @event1.type.first)
      end
    end
  end

end