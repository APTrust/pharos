require 'spec_helper'
require 'application_helper'

describe 'institutions/show.html.erb' do
  let(:institution) { FactoryBot.create :member_institution }
  let(:user) { FactoryBot.create(:user, :admin, institution: institution) }

  before do
    assign(:user, user)
    assign(:institution, institution)
    controller.stub(:current_user).and_return user
  end

  describe 'A user with access' do
    before do
      allow(view).to receive(:policy).and_return double(show?: true, edit?: true, enable_otp?: true, disable_otp?: true, mass_forced_password_update?: true)
      render
    end

    it 'displays the page header' do
      rendered.should have_css('h1', text: institution.name)
    end

    it 'has a link to view associated users' do
      rendered.should have_link('Users')
    end
  end
end