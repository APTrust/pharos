require 'spec_helper'
require 'application_helper'

describe 'users/index.html.erb' do
  let(:institution) { FactoryBot.create :member_institution }
  let(:user) { FactoryBot.create(:user, :admin, institution: institution) }

  before do
    assign(:user, user)
    assign(:institution, institution)
    assign(:users, [
                            stub_model(User, name: 'Kelly Cobb', id: 1, institution: institution),
                            stub_model(User, name: 'Andrew Diamond', id: 2, institution: institution)
                        ])
    controller.stub(:current_user).and_return user
  end

  describe 'A user with access' do
    before do
      allow(view).to receive(:policy).and_return double(show?:true, edit?:true, create?:true, destroy?:true, deactivate?:true)
      render
    end

    it 'displays the page header' do
      rendered.should have_css('h1', text: 'Users')
    end

    it 'has a link to edit a user' do
      rendered.should have_link('View', href: user_path(1))
      rendered.should have_link('Edit', href: '/users/1/edit')
      rendered.should have_link('Delete', href: '/users/1')
    end
  end

  describe 'A user without access' do
    before do
      allow(view).to receive(:policy).and_return double(show?:false, edit?:false, create?:false, destroy?:false, deactivate?:false)
      render
    end

    it 'should not display the links' do
      rendered.should_not have_link('View', href: user_path(1))
      rendered.should_not have_link('Edit', href: '/users/1/edit')
      rendered.should_not have_link('Delete', href: '/users/1')
    end
  end
end