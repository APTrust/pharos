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
    @institution = FactoryGirl.create(:institution)
    @another_institution = FactoryGirl.create(:institution)

    @object_one = FactoryGirl.create(:consortial_intellectual_object, institution_id: @institution.id)
    @object_two = FactoryGirl.create(:institutional_intellectual_object, institution_id: @institution.id, alt_identifier: ['something/1234-5678'])
    @object_three = FactoryGirl.create(:restricted_intellectual_object, institution_id: @institution.id, bag_name: 'fancy_bag/1234-5678')
    @object_four = FactoryGirl.create(:consortial_intellectual_object, institution_id: @another_institution.id, title: 'This is an important bag')
    @object_five = FactoryGirl.create(:institutional_intellectual_object, institution_id: @another_institution.id, identifier: 'test.edu/1234-5678')
    @object_six = FactoryGirl.create(:restricted_intellectual_object, institution_id: @another_institution.id)

    @file_one = FactoryGirl.create(:generic_file, intellectual_object: @object_one, uri: 'file://something/data/old_file.xml')
    @file_two = FactoryGirl.create(:generic_file, intellectual_object: @object_two, uri: 'file://fancy/data/new_file.xml')
    @file_three = FactoryGirl.create(:generic_file, intellectual_object: @object_three, identifier: 'something/1234-5678/data/new_file.xml')
    @file_four = FactoryGirl.create(:generic_file, intellectual_object: @object_four)
    @file_five = FactoryGirl.create(:generic_file, intellectual_object: @object_five)
    @file_six = FactoryGirl.create(:generic_file, intellectual_object: @object_six)

    @item_one = FactoryGirl.create(:work_item, object_identifier: @object_one.identifier, generic_file_identifier: @file_one.identifier)
    @item_two = FactoryGirl.create(:work_item, object_identifier: @object_two.identifier, generic_file_identifier: @file_two.identifier, etag: '1234-5678')
    @item_three = FactoryGirl.create(:work_item, object_identifier: @object_three.identifier, generic_file_identifier: @file_three.identifier)
    @item_four = FactoryGirl.create(:work_item, object_identifier: @object_four.identifier, generic_file_identifier: @file_four.identifier, stage: 'Requested')
    @item_five = FactoryGirl.create(:work_item, object_identifier: @object_five.identifier, generic_file_identifier: @file_five.identifier, name: '1234file.tar', status: 'Success')
    @item_six = FactoryGirl.create(:work_item, object_identifier: @object_six.identifier, generic_file_identifier: @file_six.identifier, action: 'Ingest')
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
            get :search, q: @object_one.identifier, search_field: 'identifier', object_type: 'object'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_one.id
          end

          it 'should match a partial search on alt_identifier' do
            get :search, q: 'something', search_field: 'alt_identifier', object_type: 'object'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_two.id
          end

          it 'should match a partial search on bag_name' do
            get :search, q: 'fancy_bag', search_field: 'bag_name', object_type: 'object'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_three.id
          end

          it 'should match a partial search on title' do
            get :search, q: 'important', search_field: 'title', object_type: 'object'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @object_four.id
          end

          it 'should return results from multiple categories when search_field is generic' do
            get :search, q: '1234-5678', search_field: '*', object_type: 'object'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_two.id, @object_three.id, @object_five.id]
          end
        end

        describe 'for generic file searches' do
          it 'should match an exact search on identifier' do
            get :search, q: @file_one.identifier, search_field: 'identifier', object_type: 'file'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @file_one.id
          end

          it 'should match a partial search on uri' do
            get :search, q: 'fancy', search_field: 'uri', object_type: 'file'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @file_two.id
          end

          it 'should return results from multiple categories when search_field is generic' do
            get :search, q: 'new_file.xml', search_field: '*', object_type: 'file'
            expect(assigns(:paged_results).size).to eq 2
            expect(assigns(:paged_results).map &:id).to match_array [@file_two.id, @file_three.id]
          end
        end

        describe 'for work item searches' do
          it 'should match an exact search on name' do
            get :search, q: @item_one.name, search_field: 'name', object_type: 'item'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @item_one.id
          end

          it 'should match a partial search on etag' do
            get :search, q: '1234', search_field: 'etag', object_type: 'item'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @item_two.id
          end

          it 'should match a search on object_identifier' do
            get :search, q: @object_three.identifier, search_field: 'object_identifier', object_type: 'item'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @item_three.id
          end

          it 'should match a search on file_identifier' do
            get :search, q: @file_four.identifier, search_field: 'file_identifier', object_type: 'item'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).first.id).to eq @item_four.id
          end

          it 'should return results from multiple categories when search_field is generic' do
            get :search, q: '1234', search_field: '*', object_type: 'item'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@item_two.id, @item_three.id, @item_five.id]
          end
        end

        describe 'for generic searches' do
          it 'should match a search on identifier' do
            get :search, q: '1234', search_field: 'identifier', object_type: '*'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_five.id, @file_three.id, @file_five.id]
          end

          it 'should match a search on alt_identifier' do
            get :search, q: '1234', search_field: 'alt_identifier', object_type: '*'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_two.id, @item_three.id, @item_five.id]
          end

          it 'should match a search on bag_name' do
            get :search, q: '1234', search_field: 'bag_name', object_type: '*'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_three.id, @object_five.id, @item_five.id]
          end

          it 'should match a search on title' do
            get :search, q: 'important', search_field: 'title', object_type: '*'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@object_four.id]
          end

          it 'should match a search on uri' do
            get :search, q: 'new_file', search_field: 'uri', object_type: '*'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@file_two.id]
          end

          it 'should match a search on name' do
            get :search, q: '1234', search_field: 'name', object_type: '*'
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_three.id, @object_five.id, @item_five.id]
          end

          it 'should match a search on etag' do
            get :search, q: '1234', search_field: 'etag', object_type: '*'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@item_two.id]
          end

          it 'should match a search on object_identifier' do
            get :search, q: '1234', search_field: 'object_identifier', object_type: '*'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@item_five.id]
          end

          it 'should match a search on generic_file_identifier' do
            get :search, q: '1234', search_field: 'file_identifier', object_type: '*'
            expect(assigns(:paged_results).size).to eq 2
            expect(assigns(:paged_results).map &:id).to match_array [@item_three.id, @item_five.id]
          end

          it 'should return all results when nonspecific search terms are used' do
            get :search, q: '*', search_field: '*', object_type: '*', per_page: 20
            expect(assigns(:paged_results).size).to eq 18
          end
        end
      end

      describe 'as an institutional admin user' do
        before do
          sign_in inst_admin
        end

        describe 'for intellectual object searches' do
          it 'should return only the results to which you have access' do
            get :search, q: '*', search_field: '*', object_type: 'object'
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@object_one.id, @object_four.id, @object_five.id, @object_six.id]
          end

          it 'should not return results that you do not have access to' do
            get :search, q: @object_three.identifier, search_field: 'identifier', object_type: 'object'
            expect(assigns(:paged_results).size).to eq 0
          end
        end

        describe 'for generic file searches' do
          it 'should return only the results to which you have access' do
            get :search, q: '*', search_field: '*', object_type: 'file'
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@file_one.id, @file_four.id, @file_five.id, @file_six.id]
          end

          it 'should not return results that you do not have access to' do
            get :search, q: @file_three.identifier, search_field: 'identifier', object_type: 'file'
            expect(assigns(:paged_results).size).to eq 0
          end
        end

        describe 'for work item searches' do
          it 'should return only the results to which you have access' do
            get :search, q: '*', search_field: '*', object_type: 'item'
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@item_one.id, @item_four.id, @item_five.id, @item_six.id]
          end

          it 'should not return results that you do not have access to' do
            get :search, q: @item_three.object_identifier, search_field: 'object_identifier', object_type: 'item'
            expect(assigns(:paged_results).size).to eq 0
          end
        end

        describe 'for generic searches' do
          it 'should return only the results to which you have access' do
            get :search, q: '*', search_field: '*', object_type: '*', per_page: 20
            expect(assigns(:paged_results).size).to eq 12
          end

          it 'should not return results that you do not have access to' do
            get :search, q: '1234', search_field: 'alt_identifier', object_type: '*'
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@item_five.id]
          end
        end
      end

      #Since permissions for inst admins and inst users are the same for searching purposes, this section will test filtering
      describe 'as an institutional user' do
        before do
          sign_in inst_user
        end

        describe 'for intellectual object searches' do
          it 'should filter results by institution' do
            get :search, q: '*', search_field: '*', object_type: 'object', institution: @another_institution.id
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@object_four.id, @object_five.id, @object_six.id]
          end

          it 'should filter results by access' do
            get :search, q: '*', search_field: '*', object_type: 'object', access: 'consortia'
            expect(assigns(:paged_results).size).to eq 2
            expect(assigns(:paged_results).map &:id).to match_array [@object_one.id, @object_four.id]
          end

          # it 'should filter results by format' do
          #   get :search, q: '*', search_field: '*', object_type: 'object', file_format: 'application/xml'
          #   expect(assigns(:paged_results).size).to eq 6
          #   expect(assigns(:paged_results).map &:id).to match_array [@object_one.id, @object_two.id, @object_three.id, @object_four.id, @object_five.id, @object_six.id]
          # end
        end

        describe 'for generic file searches' do
          it 'should filter results by institution' do
            get :search, q: '*', search_field: '*', object_type: 'file', institution: @another_institution.id
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@file_four.id, @file_five.id, @file_six.id]
          end

          it 'should filter results by access' do
            get :search, q: '*', search_field: '*', object_type: 'file', access: 'consortia'
            expect(assigns(:paged_results).size).to eq 2
            expect(assigns(:paged_results).map &:id).to match_array [@file_one.id, @file_four.id]
          end

          it 'should filter results by format' do
            get :search, q: '*', search_field: '*', object_type: 'file', file_format: 'application/xml'
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@file_one.id, @file_four.id, @file_five.id, @file_six.id]
          end

          it 'should filter results by association' do
            get :search, q: '*', search_field: '*', object_type: 'file', association: @object_four.id
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@file_four.id]
          end
        end

        describe 'for work item searches' do
          it 'should filter results by institution' do
            get :search, q: '*', search_field: '*', object_type: 'item', institution: @another_institution.id
            expect(assigns(:paged_results).size).to eq 3
            expect(assigns(:paged_results).map &:id).to match_array [@item_four.id, @item_five.id, @item_six.id]
          end

          it 'should filter results by access' do
            get :search, q: '*', search_field: '*', object_type: 'item', access: 'consortia'
            expect(assigns(:paged_results).size).to eq 2
            expect(assigns(:paged_results).map &:id).to match_array [@item_one.id, @item_four.id]
          end

          it 'should filter results by association' do
            get :search, q: '*', search_field: '*', object_type: 'item', association: @object_four.id
            expect(assigns(:paged_results).size).to eq 1
            expect(assigns(:paged_results).map &:id).to match_array [@item_four.id]
          end

          it 'should filter results by status' do
            get :search, q: '*', search_field: '*', object_type: 'item', status: 'Success'
            expect(assigns(:paged_results).map &:id).to include(@item_five.id)
          end

          it 'should filter results by stage' do
            get :search, q: '*', search_field: '*', object_type: 'item', stage: 'Requested'
            expect(assigns(:paged_results).map &:id).to include(@item_four.id)
          end

          it 'should filter results by action' do
            get :search, q: '*', search_field: '*', object_type: 'item', object_action: 'Ingest'
            expect(assigns(:paged_results).map &:id).to include(@item_six.id)
          end
        end

        describe 'for generic searches' do
          it 'should filter results by type' do
            get :search, q: '*', search_field: '*', object_type: '*', per_page: 20, type: 'generic_file'
            expect(assigns(:paged_results).size).to eq 4
            expect(assigns(:paged_results).map &:id).to match_array [@file_one.id, @file_four.id, @file_five.id, @file_six.id]
          end
        end
      end
    end
  end

end
