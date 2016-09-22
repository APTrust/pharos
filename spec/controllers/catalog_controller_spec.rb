require 'spec_helper'

RSpec.describe CatalogController, type: :controller do

  let(:admin_user) { FactoryGirl.create(:user, :admin, institution_id: @institution.id) }
  let(:inst_admin) { FactoryGirl.create(:user, :institutional_admin, institution_id: @another_institution.id) }
  let(:inst_user) { FactoryGirl.create(:user, :institutional_user, institution_id: @another_institution.id)}

  before(:all) do
    Institution.delete_all
    IntellectualObject.delete_all
    GenericFile.delete_all
    WorkItem.delete_all
    PremisEvent.delete_all
    @institution = FactoryGirl.create(:institution)
    @another_institution = FactoryGirl.create(:institution)

    @object_one = FactoryGirl.create(:consortial_intellectual_object, institution_id: @institution.id, id: 1)
    @object_two = FactoryGirl.create(:institutional_intellectual_object, institution_id: @institution.id, alt_identifier: ['something/1234-5678'], id: 2)
    @object_three = FactoryGirl.create(:restricted_intellectual_object, institution_id: @institution.id, bag_name: 'fancy_bag/1234-5678', id: 3)
    @object_four = FactoryGirl.create(:consortial_intellectual_object, institution_id: @another_institution.id, title: 'This is an important bag', id: 4)
    @object_five = FactoryGirl.create(:institutional_intellectual_object, institution_id: @another_institution.id, identifier: 'test.edu/1234-5678', id: 5)
    @object_six = FactoryGirl.create(:restricted_intellectual_object, institution_id: @another_institution.id, id: 6)

    @file_one = FactoryGirl.create(:generic_file, intellectual_object: @object_one, uri: 'file://something/data/old_file.xml', id: 7)
    @file_two = FactoryGirl.create(:generic_file, intellectual_object: @object_two, uri: 'file://fancy/data/new_file.xml', id: 8)
    @file_three = FactoryGirl.create(:generic_file, intellectual_object: @object_three, identifier: 'something/1234-5678/data/new_file.xml', id: 9)
    @file_four = FactoryGirl.create(:generic_file, intellectual_object: @object_four, id: 10)
    @file_five = FactoryGirl.create(:generic_file, intellectual_object: @object_five, id: 11)
    @file_six = FactoryGirl.create(:generic_file, intellectual_object: @object_six, id: 12)

    @item_one = FactoryGirl.create(:ingested_item, object_identifier: @object_one.identifier, generic_file_identifier: @file_one.identifier, institution_id: @another_institution.id, id: 13)
    @item_two = FactoryGirl.create(:ingested_item, object_identifier: @object_two.identifier, generic_file_identifier: @file_two.identifier, etag: '1234-5678', id: 14)
    @item_three = FactoryGirl.create(:ingested_item, object_identifier: @object_three.identifier, generic_file_identifier: @file_three.identifier, id: 15)
    @item_four = FactoryGirl.create(:ingested_item, object_identifier: @object_four.identifier, generic_file_identifier: @file_four.identifier, stage: 'Requested', institution_id: @another_institution.id, id: 16)
    @item_five = FactoryGirl.create(:ingested_item, object_identifier: @object_five.identifier, generic_file_identifier: @file_five.identifier, name: '1234file.tar', status: 'Success', institution_id: @another_institution.id, id: 17)
    @item_six = FactoryGirl.create(:ingested_item, object_identifier: @object_six.identifier, generic_file_identifier: @file_six.identifier, action: 'Ingest', institution_id: @another_institution.id, id: 18)

    @event_one = FactoryGirl.create(:premis_event_fixity_check, intellectual_object: @object_one, identifier: '1234-5678')
    @event_two = FactoryGirl.create(:premis_event_fixity_check, intellectual_object: @object_two, generic_file: @file_two, identifier: 'not-my-event-9876')
    @event_three = FactoryGirl.create(:premis_event_fixity_check, intellectual_object: @object_three, generic_file: @file_three)
    @event_four = FactoryGirl.create(:premis_event_fixity_check, intellectual_object: @object_four)
    @event_five = FactoryGirl.create(:premis_event_ingest, intellectual_object: @object_five, generic_file: @file_five)
    @event_six = FactoryGirl.create(:premis_event_identifier_fail, intellectual_object: @object_six, generic_file: @file_six)
  end

  after(:all) do
    Institution.delete_all
    IntellectualObject.delete_all
    GenericFile.delete_all
    WorkItem.delete_all
  end

  describe 'GET #search' do
    describe 'when not signed in' do
      it 'should redirect to login' do
        get :search, institution_identifier: 'apt.edu'
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in' do
      describe 'as an admin user' do
        before do
          sign_in admin_user
        end

        describe 'for intellectual object searches' do
          it 'should match an exact search on identifier' do
            get :search, q: @object_one.identifier, search_field: 'Object Identifier', object_type: 'Intellectual Objects'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_one.id
          end

          it 'should match a partial search on alt_identifier' do
            get :search, q: 'something', search_field: 'Alternate Identifier', object_type: 'Intellectual Objects'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_two.id
          end

          it 'should match a partial search on bag_name' do
            get :search, q: 'fancy_bag', search_field: 'Bag Name', object_type: 'Intellectual Objects'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_three.id
          end

          it 'should match a partial search on title' do
            get :search, q: 'important', search_field: 'Title', object_type: 'Intellectual Objects'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_four.id
          end

          it 'should return results from multiple categories when search_field is generic' do
            get :search, q: '1234-5678', search_field: 'All Fields', object_type: 'Intellectual Objects'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_two.id, @object_three.id, @object_five.id]
          end
        end

        describe 'for generic file searches' do
          it 'should match an exact search on identifier' do
            get :search, q: @file_one.identifier, search_field: 'File Identifier', object_type: 'Generic Files'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @file_one.id
          end

          it 'should match a partial search on uri' do
            get :search, q: 'fancy', search_field: 'URI', object_type: 'Generic Files'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @file_two.id
          end

          it 'should return results from multiple categories when search_field is generic' do
            get :search, q: 'new_file.xml', search_field: 'All Fields', object_type: 'Generic Files'
            expect(assigns(:paged_results).size).to eq 2
            expect(assigns(:paged_results).map &:id).to match_array [@file_two.id, @file_three.id]
          end
        end

        describe 'for work item searches' do
          it 'should match an exact search on name' do
            get :search, q: @item_one.name, search_field: 'Name', object_type: 'Work Items'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @item_one.id
          end

          it 'should match a partial search on etag' do
            get :search, q: '1234', search_field: 'Etag', object_type: 'Work Items'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @item_two.id
          end

          it 'should match a search on object_identifier' do
            get :search, q: @object_three.identifier, search_field: 'Object Identifier', object_type: 'Work Items'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @item_three.id
          end

          it 'should match a search on file_identifier' do
            get :search, q: @file_four.identifier, search_field: 'File Identifier', object_type: 'Work Items'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @item_four.id
          end

          it 'should return results from multiple categories when search_field is generic' do
            get :search, q: '1234', search_field: 'All Fields', object_type: 'Work Items'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@item_two.id, @item_three.id, @item_five.id]
          end
        end

        describe 'for premis event searches' do
          it 'should match a search on premis event identifier' do
            get :search, q: '1234', search_field: 'Event Identifier', object_type: 'Premis Events'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@event_one.id]
          end

          it 'should match a search on intellectual object identifier' do
            get :search, q: '1234', search_field: 'Object Identifier', object_type: 'Premis Events'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@event_five.id]
          end

          it 'should match a search on generic file identifier' do
            get :search, q: '1234', search_field: 'File Identifier', object_type: 'Premis Events'
            expect(assigns(:paged_results).size).to eq 2
            expect(assigns(:paged_results).map &:id).to match_array [@event_three.id, @event_five.id]
          end

          it 'should return results from multiple categories when search_field is generic' do
            get :search, q: '1234', search_field: 'All Fields', object_type: 'Premis Events'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@event_one.id, @event_three.id, @event_five.id]
          end
        end

        describe 'for generic searches' do
          it 'should match a search on alt_identifier' do
            get :search, q: '1234', search_field: 'Alternate Identifier', object_type: 'All Types'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_two.id, @item_three.id, @item_five.id]
          end

          it 'should match a search on bag_name' do
            get :search, q: '1234', search_field: 'Bag Name', object_type: 'All Types'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_three.id, @object_five.id, @item_five.id]
          end

          it 'should match a search on title' do
            get :search, q: 'important', search_field: 'Title', object_type: 'All Types'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@object_four.id]
          end

          it 'should match a search on uri' do
            get :search, q: 'new_file', search_field: 'URI', object_type: 'All Types'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@file_two.id]
          end

          it 'should match a search on name' do
            get :search, q: '1234', search_field: 'Name', object_type: 'All Types'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_three.id, @object_five.id, @item_five.id]
          end

          it 'should match a search on etag' do
            get :search, q: '1234', search_field: 'Etag', object_type: 'All Types'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@item_two.id]
          end

          it 'should match a search on object_identifier' do
            get :search, q: '1234', search_field: 'Object Identifier', object_type: 'All Types'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_five.id, @item_five.id, @event_five.id]
          end

          it 'should match a search on generic_file_identifier' do
            get :search, q: '1234', search_field: 'File Identifier', object_type: 'All Types'
            expect(assigns(:paged_results).size).to eq 6
            expect(assigns(:paged_results).map &:id).to match_array [@file_three.id, @file_five.id, @item_three.id, @item_five.id, @event_three.id, @event_five.id]
          end

          it 'should match a search on premis event identifier' do
            get :search, q: '1234', search_field: 'Event Identifier', object_type: 'All Types'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@event_one.id]
          end

          it 'should return all results when nonspecific search terms are used' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'All Types', per_page: 30
            expect(assigns(:paged_results).size).to eq 24
          end
        end
      end

      describe 'as an institutional admin user' do
        before do
          sign_in inst_admin
        end

        describe 'for intellectual object searches' do
          it 'should return only the results to which you have access' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Intellectual Objects'
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@object_one.id, @object_four.id, @object_five.id, @object_six.id]
          end

          it 'should not return results that you do not have access to' do
            get :search, q: @object_three.identifier, search_field: 'Identifier', object_type: 'Intellectual Objects'
            expect(assigns(:paged_results).size).to eq 0
          end
        end

        describe 'for generic file searches' do
          it 'should return only the results to which you have access' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Generic Files'
            # file_one is consortial, 4,5,6 belong to same inst as user
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@file_one.id, @file_four.id, @file_five.id, @file_six.id]
          end

          it 'should not return results that you do not have access to' do
            get :search, q: @file_three.identifier, search_field: 'Identifier', object_type: 'Generic Files'
            expect(assigns(:paged_results).size).to eq 0
          end
        end

        describe 'for work item searches' do
          it 'should return only the results to which you have access' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Work Items'
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@item_one.id, @item_four.id, @item_five.id, @item_six.id]
          end

          it 'should not return results that you do not have access to' do
            get :search, q: @item_three.object_identifier, search_field: 'Intellectual Object Identifier', object_type: 'Work Items'
            expect(assigns(:paged_results).size).to eq 0
          end
        end

        describe 'for premis event searches' do
          it 'should return only the results to which you have access' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Premis Events'
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@event_one.id, @event_four.id, @event_five.id, @event_six.id]
          end

          it 'should not return results that you do not have access to' do
            get :search, q: '9876', search_field: 'Premis Event Identifier', object_type: 'Premis Events'
            expect(assigns(:paged_results).size).to eq 0
          end
        end

        describe 'for generic searches' do
          it 'should return only the results to which you have access' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'All Types', per_page: 20
            # 3 inst objects, 1 consortial object, 4 generic files, 4 work items, 4 events
            expect(assigns(:paged_results).size).to eq 16
          end

          it 'should not return results that you do not have access to' do
            get :search, q: '1234', search_field: 'Alternate Identifier', object_type: 'All Types'
            # doesn't return intellectual object with alt identifier containing terms, does return work item with terms
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@item_five.id]
          end
        end
      end

      describe 'as an institutional user' do
        before do
          sign_in inst_user
        end

        describe 'for intellectual object searches' do
          it 'should filter results by institution' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Intellectual Objects', institution: @another_institution.id
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_four.id, @object_five.id, @object_six.id]
          end

          it 'should filter results by access' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Intellectual Objects', access: 'consortia'
            expect(assigns(:paged_results).size).to eq 2
            expect(assigns(:paged_results).map &:id).to match_array [@object_one.id, @object_four.id]
          end

          it 'should filter results by format' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Intellectual Objects', file_format: 'application/xml'
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@object_one.id, @object_four.id, @object_five.id, @object_six.id]
          end
        end

        describe 'for generic file searches' do
          it 'should filter results by institution' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Generic Files', institution: @another_institution.id
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@file_four.id, @file_five.id, @file_six.id]
          end

          it 'should filter results by access' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Generic Files', access: 'consortia'
            expect(assigns(:paged_results).size).to eq 2
            expect(assigns(:paged_results).map &:id).to match_array [@file_one.id, @file_four.id]
          end

          it 'should filter results by format' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Generic Files', file_format: 'application/xml'
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@file_one.id, @file_four.id, @file_five.id, @file_six.id]
          end

          it 'should filter results by object association' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Generic Files', object_association: @object_four.id
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@file_four.id]
          end
        end

        describe 'for work item searches' do
          it 'should filter results by institution' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Work Items', institution: @another_institution.id
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@item_one.id, @item_four.id, @item_five.id, @item_six.id]
          end

          it 'should filter results by access' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Work Items', access: 'consortia'
            expect(assigns(:paged_results).size).to eq 2
            expect(assigns(:paged_results).map &:id).to match_array [@item_one.id, @item_four.id]
          end

          it 'should filter results by object association' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Work Items', object_association: @object_four.id
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@item_four.id]
          end

          it 'should filter results by file association' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Work Items', file_association: @file_four.id
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@item_four.id]
          end

          it 'should filter results by status' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Work Items', status: 'Success'
            expect(assigns(:paged_results).map &:id).to include(@item_five.id)
          end

          it 'should filter results by stage' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Work Items', stage: 'Requested'
            expect(assigns(:paged_results).map &:id).to include(@item_four.id)
          end

          it 'should filter results by action' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Work Items', object_action: 'Ingest'
            expect(assigns(:paged_results).map &:id).to include(@item_six.id)
          end
        end

        describe 'for premis event searches' do
          it 'should filter by institution' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Premis Events', institution: @another_institution.id
            expect(assigns(:paged_results).map &:id).to match_array [@event_four.id, @event_five.id, @event_six.id]
          end

          it 'should filter by access' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Premis Events', access: 'consortia'
            expect(assigns(:paged_results).map &:id).to match_array [@event_one.id, @event_four.id]
          end

          it 'should filter by object association' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Premis Events', object_association: @object_four.id
            expect(assigns(:paged_results).map &:id).to include(@event_four.id)
          end

          it 'should filter by file association' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Premis Events', file_association: @file_five.id
            expect(assigns(:paged_results).map &:id).to include(@event_five.id)
          end

          it 'should filter by event type' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Premis Events', event_type: 'ingest'
            expect(assigns(:paged_results).map &:id).to include(@event_five.id)
          end

          it 'should filter by outcome' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'Premis Events', outcome: 'failure'
            expect(assigns(:paged_results).map &:id).to include(@event_six.id)
          end
        end

        describe 'for generic searches' do
          it 'should filter results by type' do
            get :search, q: '*', search_field: 'All Fields', object_type: 'All Types', per_page: 20, type: 'Generic Files'
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@file_one.id, @file_four.id, @file_five.id, @file_six.id]
          end
        end
      end
    end
  end

  describe 'GET #feed' do
    before do
      sign_in admin_user
    end

    it 'returns an RSS feed with current work items' do
      get :feed, format: 'rss'
      expect(response).to be_success
      expect(response).to render_template('catalog/feed')
      expect(response.content_type).to eq('application/rss+xml')
    end
  end

end
