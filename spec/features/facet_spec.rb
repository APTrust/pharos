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
        @event3 = file.add_event(FactoryGirl.attributes_for(:premis_event_fixity_generation))
        file.save!
      end

      # ----------------------------------------------------------------
      # TODO: Bring these tests up to date. They are looking for
      # Blacklight UI elements, which we're no longer using.
      # These templates don't exist yet, and should the path be taking
      # an institution as a parameter?
      # ----------------------------------------------------------------

      # it 'facet by event type' do
      #   visit events_path(inst)
      #   page.should have_css('#documents .document', count: 3)

      #   within('#facets .blacklight-event_type_ssim') do
      #     click_link 'Type 2'
      #   end

      #   page.should have_css('#documents .document', count: 1)

      #   page.should have_css('dd', text: @event2.outcome.first)
      #   page.should_not have_css('dd', text: @event1.outcome.first)
      #   page.should have_css('dd', text: @event2.type.first)
      #   page.should_not have_css('dd', text: @event1.type.first)
      # end

      # it 'facet by event outcome' do
      #   visit events_path(inst)
      #   page.should have_css('#documents .document', count: 3)

      #   within('#facets .blacklight-event_outcome_ssim') do
      #     click_link 'Outcome 2'
      #   end

      #   page.should have_css('#documents .document', count: 1)

      #   page.should have_css('dd', text: @event2.outcome.first)
      #   page.should_not have_css('dd', text: @event1.outcome.first)
      #   page.should have_css('dd', text: @event2.type.first)
      #   page.should_not have_css('dd', text: @event1.type.first)
      # end

    end
  end

end
