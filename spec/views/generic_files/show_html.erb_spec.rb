require 'spec_helper'
require 'application_helper'

describe 'generic_files/show.html.erb' do
  let(:institution) { FactoryBot.create :member_institution }
  let(:user) { FactoryBot.create :user, :admin, institution: institution }
  let(:object) { FactoryBot.create :intellectual_object, institution: institution }
  let(:file) { FactoryBot.create :generic_file, intellectual_object: object }

  before do
    assign(:user, user)
    assign(:institution, institution)
    assign(:generic_file, file)
    assign(:intellectual_object, object)
    controller.stub(:current_user).and_return user
  end

  describe 'A user with access' do
    before do
      allow(view).to receive(:policy).and_return double(show?: true, edit?: true, destroy?: true, restore?: true)
      render
    end

    it 'displays the header' do
      rendered.should have_css('h2', text: file.identifier)
    end

    it 'has a links to manipulate the file' do
      rendered.should have_link('Delete', href: generic_file_path(file))
      rendered.should have_link('Restore File', href: generic_file_restore_path(file))
    end
  end

  describe 'A user without access' do
    before do
      allow(view).to receive(:policy).and_return double(show?: true, edit?: false, destroy?: false, restore?: false)
      render
    end

    it 'displays the header' do
      rendered.should have_css('h2', text: file.identifier)
    end

    it 'does not have a link to delete the file' do
      rendered.should_not have_link('Delete', href: generic_file_path(file))
    end
  end
end