require 'spec_helper'

RSpec.describe CatalogController, type: :controller do

  let(:admin_user) { FactoryBot.create(:user, :admin, institution_id: @institution.id) }
  let(:inst_admin) { FactoryBot.create(:user, :institutional_admin, institution_id: @another_institution.id) }
  let(:inst_user) { FactoryBot.create(:user, :institutional_user, institution_id: @another_institution.id)}

  before(:all) do
    GenericFile.delete_all
    IntellectualObject.delete_all
    WorkItem.delete_all
    PremisEvent.delete_all
    DpnWorkItem.delete_all
    User.delete_all
    Institution.delete_all

    @institution = FactoryBot.create(:member_institution)
    @another_institution = FactoryBot.create(:subscription_institution)

    @object_one = FactoryBot.create(:consortial_intellectual_object, institution_id: @institution.id, id: 1, bag_group_identifier: 'This is a collection.')
    @object_two = FactoryBot.create(:institutional_intellectual_object, institution_id: @institution.id, alt_identifier: ['something/1234-5678'], id: 2)
    @object_three = FactoryBot.create(:restricted_intellectual_object, institution_id: @institution.id, bag_name: 'fancy_bag/1234-5678', id: 3)
    @object_four = FactoryBot.create(:consortial_intellectual_object, institution_id: @another_institution.id, title: 'This is an important bag', id: 4)
    @object_five = FactoryBot.create(:institutional_intellectual_object, institution_id: @another_institution.id, identifier: 'test.edu/1234-5678', id: 5)
    @object_six = FactoryBot.create(:restricted_intellectual_object, institution_id: @another_institution.id, id: 6)

    @file_one = FactoryBot.create(:generic_file, intellectual_object: @object_one, uri: 'file://something/data/old_file.xml', id: 7)
    @file_two = FactoryBot.create(:generic_file, intellectual_object: @object_two, uri: 'file://fancy/data/new_file.xml', id: 8)
    @file_three = FactoryBot.create(:generic_file, intellectual_object: @object_three, identifier: 'something/1234-5678/data/new_file.xml', id: 9)
    @file_four = FactoryBot.create(:generic_file, intellectual_object: @object_four, id: 10)
    @file_five = FactoryBot.create(:generic_file, intellectual_object: @object_five, id: 11)
    @file_six = FactoryBot.create(:generic_file, intellectual_object: @object_six, id: 12)

    @item_one = FactoryBot.create(:ingested_item, object_identifier: @object_one.identifier, generic_file_identifier: @file_one.identifier, institution_id: @another_institution.id, id: 13)
    @item_two = FactoryBot.create(:ingested_item, object_identifier: @object_two.identifier, generic_file_identifier: @file_two.identifier, etag: '1234-5678', id: 14)
    @item_three = FactoryBot.create(:ingested_item, object_identifier: @object_three.identifier, generic_file_identifier: @file_three.identifier, name: '1234-5678', id: 15)
    @item_four = FactoryBot.create(:ingested_item, object_identifier: @object_four.identifier, generic_file_identifier: @file_four.identifier, stage: 'Requested', institution_id: @another_institution.id, id: 16)
    @item_five = FactoryBot.create(:ingested_item, object_identifier: @object_five.identifier, generic_file_identifier: @file_five.identifier, name: '1234file.tar', status: 'Success', institution_id: @another_institution.id, id: 17)
    @item_six = FactoryBot.create(:ingested_item, object_identifier: @object_six.identifier, generic_file_identifier: @file_six.identifier, action: 'Ingest', institution_id: @another_institution.id, id: 18)

    @event_one = FactoryBot.create(:premis_event_fixity_check, intellectual_object: @object_one, identifier: '1234-5678')
    @event_two = FactoryBot.create(:premis_event_fixity_check, intellectual_object: @object_two, generic_file: @file_two, identifier: 'not-my-event-9876')
    @event_three = FactoryBot.create(:premis_event_fixity_check, intellectual_object: @object_three, generic_file: @file_three)
    @event_four = FactoryBot.create(:premis_event_fixity_check, intellectual_object: @object_four)
    @event_five = FactoryBot.create(:premis_event_ingest, intellectual_object: @object_five, generic_file: @file_five)
    @event_six = FactoryBot.create(:premis_event_identifier_fail, intellectual_object: @object_six, generic_file: @file_six)

    @dpn_one = FactoryBot.create(:dpn_work_item, identifier: '1234-5678', remote_node: 'hathi', status: 'Success', stage: 'Record')
    @dpn_two = FactoryBot.create(:dpn_work_item, remote_node: 'sdr', status: 'Cancelled', stage: 'Store', retry: false)
    @dpn_three = FactoryBot.create(:dpn_work_item, remote_node: 'sdr', queued_at: nil, status: 'Success', stage: 'Store')
  end

  after(:all) do
    GenericFile.delete_all
    IntellectualObject.delete_all
    WorkItem.delete_all
    PremisEvent.delete_all
    DpnWorkItem.delete_all
    User.delete_all
    Institution.delete_all
  end

  describe 'GET #search' do
    describe 'when not signed in' do
      it 'should redirect to login' do
        get :search, params: { institution_identifier: 'apt.edu' }
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
            get :search, params: { q: @object_one.identifier, search_field: 'Object Identifier', object_type: 'Intellectual Objects' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_one.id
          end

          it 'should match a partial search on alt_identifier' do
            get :search, params: { q: 'something', search_field: 'Alternate Identifier', object_type: 'Intellectual Objects' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_two.id
          end

          it 'should match a partial search on bag_name' do
            get :search, params: { q: 'fancy_bag', search_field: 'Bag Name', object_type: 'Intellectual Objects' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_three.id
          end

          it 'should match a partial search on title' do
            get :search, params: { q: 'important', search_field: 'Title', object_type: 'Intellectual Objects' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_four.id
          end

          it 'should match a partial search on bag group identifier' do
            get :search, params: { q: 'collection', search_field: 'Bag Group Identifier', object_type: 'Intellectual Objects' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_one.id
          end

          it 'should strip the leading and trailing whitespace from a search term' do
            get :search, params: { q: "   #{@object_one.identifier}   ", search_field: 'Object Identifier', object_type: 'Intellectual Objects' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_one.id
          end
        end

        describe 'for generic file searches' do
          it 'should match an exact search on identifier' do
            get :search, params: { q: @file_one.identifier, search_field: 'File Identifier', object_type: 'Generic Files' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @file_one.id
          end

          it 'should match a partial search on uri' do
            get :search, params: { q: 'fancy', search_field: 'URI', object_type: 'Generic Files' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @file_two.id
          end
        end

        describe 'for work item searches' do
          it 'should match an exact search on name' do
            get :search, params: { q: @item_one.name, search_field: 'Name', object_type: 'Work Items' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @item_one.id
          end

          it 'should match a partial search on etag' do
            get :search, params: { q: '1234', search_field: 'Etag', object_type: 'Work Items' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @item_two.id
          end

          it 'should match a search on object_identifier' do
            get :search, params: { q: @object_three.identifier, search_field: 'Object Identifier', object_type: 'Work Items' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @item_three.id
          end

          it 'should match a search on file_identifier' do
            get :search, params: { q: @file_four.identifier, search_field: 'File Identifier', object_type: 'Work Items' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @item_four.id
          end
        end

        describe 'for premis event searches' do
          it 'should match a search on premis event identifier' do
            get :search, params: { q: @event_one.identifier, search_field: 'Event Identifier', object_type: 'Premis Events' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@event_one.id]
          end

          it 'should match a search on intellectual object identifier' do
            get :search, params: { q: @object_five.identifier, search_field: 'Object Identifier', object_type: 'Premis Events' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@event_five.id]
          end

          it 'should match a search on generic file identifier' do
            get :search, params: { q: @file_three.identifier, search_field: 'File Identifier', object_type: 'Premis Events' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@event_three.id]
          end
        end

        describe 'for dpn item searches' do
          it 'should match a search on an item identifier' do
            get :search, params: { q: @dpn_one.identifier, search_field: 'Item Identifier', object_type: 'DPN Items' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@dpn_one.id]
          end

          it 'should bring back all results when the query is generic' do
            get :search, params: { q: '*', search_field: 'Item Identifier', object_type: 'DPN Items' }
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@dpn_one.id, @dpn_two.id, @dpn_three.id]
          end

          describe 'with filtering' do
            it 'should filter results by remote node' do
              get :search, params: { q: '*', search_field: 'Item Identifier', object_type: 'DPN Items', remote_node: 'hathi' }
              expect(assigns(:paged_results).size).to eq 1
              expect(assigns(:paged_results).map &:id).to match_array [@dpn_one.id]
            end

            it 'should filter results by queued status' do
              get :search, params: { q: '*', search_field: 'Item Identifier', object_type: 'DPN Items', queued: 'is_queued' }
              expect(assigns(:paged_results).size).to eq 2
              expect(assigns(:paged_results).map &:id).to match_array [@dpn_one.id, @dpn_two.id]
            end

            it 'should filter results by status' do
              get :search, params: { q: '*', search_field: 'Item Identifier', object_type: 'DPN Items', status: 'Success' }
              expect(assigns(:paged_results).size).to eq 2
              expect(assigns(:paged_results).map &:id).to match_array [@dpn_one.id, @dpn_three.id]
            end

            it 'should filter results by stage' do
              get :search, params: { q: '*', search_field: 'Item Identifier', object_type: 'DPN Items', stage: 'Store' }
              expect(assigns(:paged_results).size).to eq 2
              expect(assigns(:paged_results).map &:id).to match_array [@dpn_two.id, @dpn_three.id]
            end

            it 'should filter results by retry' do
              get :search, params: { q: '*', search_field: 'Item Identifier', object_type: 'DPN Items', retry: false }
              expect(assigns(:paged_results).size).to eq 1
              expect(assigns(:paged_results).map &:id).to match_array [@dpn_two.id]
            end
          end
        end

      end

      describe 'as an institutional admin user' do
        before do
          sign_in inst_admin
        end

        describe 'for intellectual object searches' do
          it 'should return only the results to which you have access' do
            get :search, params: { q: '*', search_field: 'Object Identifier', object_type: 'Intellectual Objects' }
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@object_one.id, @object_four.id, @object_five.id, @object_six.id]
          end

          it 'should not return results that you do not have access to' do
            get :search, params: { q: @object_three.identifier, search_field: 'Object Identifier', object_type: 'Intellectual Objects' }
            expect(assigns(:paged_results).size).to eq 0
          end
        end

        describe 'for generic file searches' do
          it 'should return only the results to which you have access' do
            get :search, params: { q: '*', search_field: 'File Identifier', object_type: 'Generic Files' }
            # file_one is consortial, 4,5,6 belong to same inst as user
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@file_four.id, @file_five.id, @file_six.id]
          end

          it 'should not return results that you do not have access to' do
            get :search, params: { q: @file_three.identifier, search_field: 'File Identifier', object_type: 'Generic Files' }
            expect(assigns(:paged_results).size).to eq 0
          end
        end

        describe 'for work item searches' do
          it 'should return only the results to which you have access' do
            get :search, params: { q: '*', search_field: 'Object Identifier', object_type: 'Work Items' }
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@item_one.id, @item_four.id, @item_five.id, @item_six.id]
          end

          it 'should not return results that you do not have access to' do
            get :search, params: { q: @item_three.object_identifier, search_field: 'Object Identifier', object_type: 'Work Items' }
            expect(assigns(:paged_results).size).to eq 0
          end
        end

        describe 'for premis event searches' do
          it 'should return only the results to which you have access' do
            get :search, params: { q: '*', search_field: 'Event Identifier', object_type: 'Premis Events' }
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@event_four.id, @event_five.id, @event_six.id]
          end

          it 'should not return results that you do not have access to' do
            get :search, params: { q: '9876', search_field: 'Event Identifier', object_type: 'Premis Events' }
            expect(assigns(:paged_results).size).to eq 0
          end
        end

        describe 'for dpn item searches' do
          it 'should not return results that you do not have access to' do
            get :search, params: { q: '*', search_field: 'Item Identifier', object_type: 'DPN Items' }
            expect(assigns(:paged_results).size).to eq 0
          end
        end

      end

      describe 'as an institutional user' do
        before do
          sign_in inst_user
        end

        describe 'for intellectual object searches' do
          it 'should filter results by institution' do
            get :search, params: { q: '*', search_field: 'Object Identifier', object_type: 'Intellectual Objects', institution: @another_institution.id }
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_four.id, @object_five.id, @object_six.id]
          end

          it 'should filter results by access' do
            get :search, params: { q: '*', search_field: 'Object Identifier', object_type: 'Intellectual Objects', access: 'consortia' }
            expect(assigns(:paged_results).size).to eq 2
            expect(assigns(:paged_results).map &:id).to match_array [@object_one.id, @object_four.id]
          end

          it 'should filter results by format' do
            get :search, params: { q: '*', search_field: 'Object Identifier', object_type: 'Intellectual Objects', file_format: 'application/xml' }
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@object_one.id, @object_four.id, @object_five.id, @object_six.id]
          end
        end

        describe 'for generic file searches' do
          it 'should filter results by institution' do
            get :search, params: { q: '*', search_field: 'File Identifier', object_type: 'Generic Files', institution: @another_institution.id }
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@file_four.id, @file_five.id, @file_six.id]
          end

          it 'should filter results by access' do
            get :search, params: { q: '*', search_field: 'File Identifier', object_type: 'Generic Files', access: 'consortia' }
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@file_four.id]
          end

          it 'should filter results by format' do
            get :search, params: { q: '*', search_field: 'File Identifier', object_type: 'Generic Files', file_format: 'application/xml' }
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@file_four.id, @file_five.id, @file_six.id]
          end
        end

        describe 'for work item searches' do
          it 'should filter results by institution' do
            get :search, params: { q: '*', search_field: 'Etag', object_type: 'Work Items', institution: @another_institution.id }
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@item_one.id, @item_four.id, @item_five.id, @item_six.id]
          end

          it 'should filter results by access' do
            get :search, params: { q: '*', search_field: 'Etag', object_type: 'Work Items', access: 'consortia' }
            expect(assigns(:paged_results).size).to eq 2
            expect(assigns(:paged_results).map &:id).to match_array [@item_one.id, @item_four.id]
          end

          it 'should filter results by status' do
            get :search, params: { q: '*', search_field: 'Etag', object_type: 'Work Items', status: 'Success' }
            expect(assigns(:paged_results).map &:id).to include(@item_five.id)
          end

          it 'should filter results by stage' do
            get :search, params: { q: '*', search_field: 'Etag', object_type: 'Work Items', stage: 'Requested' }
            expect(assigns(:paged_results).map &:id).to include(@item_four.id)
          end

          it 'should filter results by action' do
            get :search, params: { q: '*', search_field: 'Etag', object_type: 'Work Items', object_action: 'Ingest' }
            expect(assigns(:paged_results).map &:id).to include(@item_six.id)
          end
        end

        describe 'for premis event searches' do
          it 'should filter by institution' do
            get :search, params: { q: '*', search_field: 'Event Identifier', object_type: 'Premis Events', institution: @another_institution.id }
            expect(assigns(:paged_results).map &:id).to match_array [@event_four.id, @event_five.id, @event_six.id]
          end

          it 'should filter by access' do
            get :search, params: { q: '*', search_field: 'Event Identifier', object_type: 'Premis Events', access: 'consortia' }
            expect(assigns(:paged_results).map &:id).to match_array [@event_four.id]
          end

          it 'should filter by event type' do
            get :search, params: { q: '*', search_field: 'Event Identifier', object_type: 'Premis Events', event_type: Pharos::Application::PHAROS_EVENT_TYPES['ingest'] }
            expect(assigns(:paged_results).map &:id).to include(@event_five.id)
          end

          it 'should filter by outcome' do
            get :search, params: { q: '*', search_field: 'Event Identifier', object_type: 'Premis Events', outcome: 'Failure' }
            expect(assigns(:paged_results).map &:id).to include(@event_six.id)
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
      expect(response).to be_successful
      expect(response).to render_template('catalog/feed')
      expect(response.content_type).to eq('application/rss+xml')
    end
  end

end
