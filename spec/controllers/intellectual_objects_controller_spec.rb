require 'spec_helper'

RSpec.describe IntellectualObjectsController, type: :controller do

  let(:inst1) { FactoryGirl.create(:institution) }
  let(:inst2) { FactoryGirl.create(:institution) }
  let(:inst_user) { FactoryGirl.create(:user, :institutional_user,
                                       institution: inst1) }
  let(:inst_admin) { FactoryGirl.create(:user, :institutional_admin,
                                       institution: inst1) }
  let(:sys_admin) { FactoryGirl.create(:user, :admin) }
  let!(:obj1) { FactoryGirl.create(:consortial_intellectual_object,
                                   institution: inst2) }
  let!(:obj2) { FactoryGirl.create(:institutional_intellectual_object,
                                   institution: inst1,
                                   title: 'Aberdeen Wanderers',
                                   description: 'Founded in Aberdeen in 1928.') }
  let!(:obj3) { FactoryGirl.create(:institutional_intellectual_object,
                                   institution: inst2) }
  let!(:obj4) { FactoryGirl.create(:restricted_intellectual_object,
                                   institution: inst1,
                                   title: "Manchester City",
                                   description: 'The other Manchester team.') }
  let!(:obj5) { FactoryGirl.create(:restricted_intellectual_object,
                                   institution: inst2) }
  let!(:obj6) { FactoryGirl.create(:institutional_intellectual_object,
                                   institution: inst1,
                                   bag_name: '12345-abcde',
                                   alt_identifier: ['test.edu/some-bag'],
                                   created_at: "2011-10-10T10:00:00Z",
                                   updated_at: "2011-10-10T10:00:00Z") }

  # before do
  #   IntellectualObject.destroy_all
  #   Institution.destroy_all
  # end

  # after do
  #   IntellectualObject.destroy_all
  #   Institution.destroy_all
  # end


  describe 'GET #index' do

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :index, institution_identifier: 'apt.edu'
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before do
        sign_in inst_user
      end
      it 'should show results from my institution' do
        get :index, {}
        expect(response).to be_successful
        expect(assigns(:intellectual_objects).size).to eq 3
        expect(assigns(:intellectual_objects).map &:id).to match_array [obj2.id, obj4.id, obj6.id]
      end
    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }
      it 'should show results from my institution' do
        get :index, {}
        expect(response).to be_successful
        expect(assigns(:intellectual_objects).size).to eq 3
        expect(assigns(:intellectual_objects).map &:id).to match_array [obj2.id, obj4.id, obj6.id]
      end
    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }
      it 'should show all results' do
        get :index, {}
        expect(response).to be_successful
        expect(assigns(:intellectual_objects).size).to eq 6
        expect(assigns(:intellectual_objects).map &:id).to match_array [obj1.id, obj2.id, obj3.id,
                                                                        obj4.id, obj5.id, obj6.id]
      end
    end

  end # ---------------- END OF GET #index



  describe 'GET #show' do

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :show, intellectual_object_identifier: obj1
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }

    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }

    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }

    end

  end # ---------------- END OF GET #show ----------------



  describe 'GET #edit' do

    describe 'when not signed in' do
      it 'should redirect to login' do
        get :edit, intellectual_object_identifier: obj1
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }

    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }

    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }

    end

  end # ---------------- END OF GET #edit ----------------


  describe 'POST #create' do

    describe 'when not signed in' do
      it 'should redirect to login' do
        post :create, institution_identifier: inst1.identifier, intellectual_object: {title: 'Foo' }
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }

    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }

    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }

    end

  end # ---------------- END OF POST #create ----------------


  describe 'PATCH #update' do

    describe 'when not signed in' do
      it 'should redirect to login' do
        patch :update, intellectual_object_identifier: obj1, intellectual_object: {title: 'Foo'}
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }

    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }

    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }

    end

  end # ---------------- END OF PATCH #update ----------------


  describe 'DELETE #destroy' do

    describe 'when not signed in' do
      it 'should redirect to login' do
        delete :destroy, intellectual_object_identifier: obj1
        expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }

    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }

    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }

    end

  end # ---------------- END OF DELETE #destroy ----------------


  describe 'PUT #send_to_dpn' do

    describe 'when not signed in' do
      it 'should redirect to login' do
        # put :send_to_dpn, intellectual_object_identifier: obj1
        # expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }

    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }

    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }

    end

  end # ---------------- END OF PUT #send_to_dpn ----------------


  describe 'PUT #restore' do

    describe 'when not signed in' do
      it 'should redirect to login' do
        # put :restore, intellectual_object_identifier: obj1
        # expect(response).to redirect_to root_url + 'users/sign_in'
      end
    end

    describe 'when signed in as institutional user' do
      before { sign_in inst_user }

    end

    describe 'when signed in as institutional admin' do
      before { sign_in inst_admin }

    end

    describe 'when signed in as system admin' do
      before { sign_in sys_admin }

    end

  end # ---------------- END OF PUT #restore ----------------


end
