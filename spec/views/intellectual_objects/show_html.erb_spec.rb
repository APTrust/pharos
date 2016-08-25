require 'spec_helper'

describe 'intellectual_objects/show.html.erb' do
  let(:institution) { FactoryGirl.create :institution }
  let(:user) { FactoryGirl.create :user, :admin, institution: institution }
  let(:object) { FactoryGirl.create :intellectual_object, institution: institution }

  before do
    assign(:user, user)
    assign(:institution, institution)
    assign(:intellectual_object, object)
    controller.stub(:current_user).and_return user
  end

  describe 'A user with access' do
    before do
      allow(view).to receive(:policy).and_return double(show?: true, edit?: true, destroy?: true, restore?: true, send_to_dpn?: true)
      render
    end

    it 'displays the header' do
      rendered.should have_css('h1', text: object.title)
    end

    it 'has a links for manipulating the object' do
      rendered.should have_link('Delete', href: intellectual_object_path(object))
      rendered.should have_link('Restore Object', href: intellectual_object_restore_path(object))
      rendered.should have_link('Send Object To DPN', href: intellectual_object_send_to_dpn_path(object))
    end
  end

  describe 'A user without access' do
    before do
      allow(view).to receive(:policy).and_return double(show?: true, edit?: false, destroy?: false, restore?: false, send_to_dpn?: false)
      render
    end

    it 'displays the header' do
      rendered.should have_css('h1', text: object.title)
    end

    it 'does not have a link to delete the file' do
      rendered.should_not have_link('Delete', href: intellectual_object_path(object))
    end
  end
end