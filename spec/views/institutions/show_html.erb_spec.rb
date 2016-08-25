require 'spec_helper'

describe 'institutions/show.html.erb' do
  let(:institution) { FactoryGirl.create :institution }
  let(:user) { FactoryGirl.create(:user, :admin, institution: institution) }

  before do
    assign(:user, user)
    assign(:institution, institution)
    controller.stub(:current_user).and_return user
  end

  describe 'A user with access' do
    before do
      allow(view).to receive(:policy).and_return double(show?: true, edit?: true)
      render
    end

    it 'displays the page header' do
      rendered.should have_css('h1', text: institution.name)
    end

    it 'has a link to view associated objects' do
      rendered.should have_link('Objects')
    end
  end
end