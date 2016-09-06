require 'spec_helper'

describe 'work_items/show.html.erb' do
  let(:institution) { FactoryGirl.create :institution }
  let(:user) { FactoryGirl.create :user, :admin, institution: institution }
  let(:object) { FactoryGirl.create :intellectual_object, institution: institution }
  let(:file) { FactoryGirl.create :generic_file, intellectual_object: object }
  let(:item) { FactoryGirl.create :work_item, object_identifier: object.identifier, generic_file_identifier: file.identifier }
  let(:state_item) { FactoryGirl.create :work_item_state, work_item: item }

  before do
    assign(:user, user)
    assign(:institution, institution)
    assign(:generic_file, file)
    assign(:intellectual_object, object)
    assign(:work_item, item)
    controller.stub(:current_user).and_return user
  end

  describe 'A user with access' do
    before do
      allow(view).to receive(:policy).and_return double(show?: true, edit?: true, destroy?: true)
      render
    end

    it 'displays the header' do
      rendered.should have_css('h2', text: item.name)
    end
  end

  describe 'A user without access' do
    before do
      allow(view).to receive(:policy).and_return double(show?: true, edit?: false, destroy?: false)
      render
    end

    it 'displays the header' do
      rendered.should have_css('h2', text: item.name)
    end
  end
end