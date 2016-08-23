require 'spec_helper'

describe 'API Authentication: Editing an Intellectual Object via API request' do
  let(:inst) { FactoryGirl.create :institution }

  let(:old_title) { 'Old Title' }
  let(:new_title) { 'New Title' }
  let(:obj) { FactoryGirl.create :intellectual_object, institution: inst, title: old_title }

  let(:update_fields) {
    { id: obj.id, intellectual_object: { title: new_title }}
  }
  let(:initial_headers) {{ 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json' }}

  let(:valid_key) { '123' }
  let(:invalid_key) { '456' }
  let(:user) { FactoryGirl.create :user, :institutional_admin, institution_id: inst.id, api_secret_key: valid_key }

  after do
    Institution.destroy_all
  end

  describe 'Valid login' do
    let(:login_headers) {{ 'X-Pharos-API-User' => user.email, 'X-Pharos-API-Key' => valid_key }}

    it 'should not update the object' do
      params = update_fields.to_json
      headers = initial_headers.merge(login_headers)
      response = patch(intellectual_object_path(obj), params, headers)
      response.should == 403
      #obj.reload.title.should == new_title
    end
  end

  describe 'Log in with valid user, but invalid API key' do
    let(:login_headers) {{ 'X-Pharos-API-User' => user.email, 'X-Pharos-API-Key' => invalid_key }}

    it 'fails to log in' do
      params = update_fields.to_json
      headers = initial_headers.merge(login_headers)
      response = patch(intellectual_object_path(obj), params, headers)
      response.should == 401
      obj.reload.title.should == old_title
    end
  end

  describe 'Log in with invalid user' do
    let(:login_headers) {{ 'X-Pharos-API-User' => 'not_a_user@example.com', 'X-Pharos-API-Key' => valid_key }}

    it 'fails to log in' do
      params = update_fields.to_json
      headers = initial_headers.merge(login_headers)
      response = patch(intellectual_object_path(obj), params, headers)
      response.should == 401
      obj.reload.title.should == old_title
    end
  end

  describe 'A user without an API key' do
    let(:user_without_key) { FactoryGirl.create :user, :institutional_admin, institution_id: inst.id }
    let(:login_headers) {{ 'X-Pharos-API-User' => user_without_key.email, 'X-Pharos-API-Key' => nil }}

    it 'cannot log in via API request' do
      params = update_fields.to_json
      headers = initial_headers.merge(login_headers)
      response = patch(intellectual_object_path(obj), params, headers)
      response.should == 401
      obj.reload.title.should == old_title
    end
  end

end