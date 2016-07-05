require 'spec_helper'

RSpec.describe CatalogController, type: :controller do

  let(:admin_user) { FactoryGirl.create(:user, :admin, institution_id: @institution.id) }
  let(:inst_admin) { FactoryGirl.create(:user, :institutional_admin, institution_id: @another_institution.id) }
  let(:inst_user) { FactoryGirl.create(:user, :institutional_user, institution_id: @another_institution.id)}

  before(:all) do
    @institution = FactoryGirl.create(:institution)
    @another_institution = FactoryGirl.create(:institution)
    @object_one = FactoryGirl.create(:consortial_intellectual_object, institution_id: @institution.id)
    @object_two = FactoryGirl.create(:institutional_intellectual_object, institution_id: @institution.id)
    @object_three = FactoryGirl.create(:restricted_intellectual_object, institution_id: @institution.id)
    @object_four = FactoryGirl.create(:consortial_intellectual_object, institution_id: @another_institution.id)
    @object_five = FactoryGirl.create(:institutional_intellectual_object, institution_id: @another_institution.id)
    @object_six = FactoryGirl.create(:restricted_intellectual_object, institution_id: @another_institution.id)
    @file_one = FactoryGirl.create(:generic_file, intellectual_object_id: @object_one.id)
    @file_two = FactoryGirl.create(:generic_file, intellectual_object_id: @object_two.id)
    @file_three = FactoryGirl.create(:generic_file, intellectual_object_id: @object_three.id)
    @file_four = FactoryGirl.create(:generic_file, intellectual_object_id: @object_four.id)
    @file_five = FactoryGirl.create(:generic_file, intellectual_object_id: @object_five.id)
    @file_six = FactoryGirl.create(:generic_file, intellectual_object_id: @object_six.id)
    @event_one = FactoryGirl.create(:premis_event_ingest, intellectual_object_id: @object_one.id)
    @event_two = FactoryGirl.create(:premis_event_ingest, intellectual_object_id: @object_two.id)
    @event_three = FactoryGirl.create(:premis_event_ingest, intellectual_object_id: @object_three.id)
    @event_four = FactoryGirl.create(:premis_event_ingest, intellectual_object_id: @object_four.id)
    @event_five = FactoryGirl.create(:premis_event_ingest, intellectual_object_id: @object_five.id)
    @event_six = FactoryGirl.create(:premis_event_ingest, intellectual_object_id: @object_six.id)
    @item_one = FactoryGirl.create(:work_item, intellectual_object_id: @object_one.id)
    @item_two = FactoryGirl.create(:work_item, intellectual_object_id: @object_two.id)
    @item_three = FactoryGirl.create(:work_item, intellectual_object_id: @object_three.id)
    @item_four = FactoryGirl.create(:work_item, intellectual_object_id: @object_four.id)
    @item_five = FactoryGirl.create(:work_item, intellectual_object_id: @object_five.id)
    @item_six = FactoryGirl.create(:work_item, intellectual_object_id: @object_six.id)
  end

  after(:all) do
    Institution.delete_all
    IntellectualObject.delete_all
    GenericFile.delete_all
    WorkItem.delete_all
  end

  describe 'GET #search' do
    describe 'for an admin user' do
      before do
        sign_in admin_user
      end
    end

    describe 'for an institutional admin user' do
      before do
        sign_in inst_admin
      end
    end

    describe 'for an institutional user' do
      before do
        sign_in inst_user
      end
    end
  end

end
