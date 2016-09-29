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
    let(:user) { FactoryGirl.create(:user, :institutional_admin, institution_id: inst.id) }

    before do
      login_as user
    end

    describe 'Events list' do
      before do
        @event1 = file.add_event(FactoryGirl.attributes_for(:premis_event_ingest))
        @event2 = file.add_event(FactoryGirl.attributes_for(:premis_event_validation))
        @event3 = file.add_event(FactoryGirl.attributes_for(:premis_event_fixity_generation, outcome: 'Failure'))
        file.save!
      end

      it 'facet by event type' do
        visit institution_events_path(inst)
        page.should have_css('#documents .document', count: 3)

        within('#event_type-parent') do
          click_link 'Validation'
        end

        page.should have_css('#documents .document', count: 1)

        page.should have_css('dd', text: @event2.outcome)
        page.should have_css('dd', text: @event2.event_type)
        page.should_not have_css('dd', text: @event1.event_type)
      end

      it 'facet by event outcome' do
        visit institution_events_path(inst)
        page.should have_css('#documents .document', count: 3)

        within('#outcome-parent') do
          click_link 'Success'
        end

        page.should have_css('#documents .document', count: 2)

        page.should have_css('dd', text: @event2.event_type)
        page.should have_css('dd', text: @event1.event_type)
        page.should_not have_css('dd', text: @event3.event_type)
      end

    end
  end

end
