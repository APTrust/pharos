require 'spec_helper'

describe 'institutions/index.html.erb' do
  let(:institution) { FactoryGirl.create :institution }
  let(:user) { FactoryGirl.create(:user, :admin, institution: institution) }
  let(:sizes) { { 'APTrust' => 500, 'University of Virginia' => 500 } }

  before do
    assign(:user, user)
    assign(:sizes, sizes)
    assign(:institution, institution)
    assign(:institutions, [
                            stub_model(Institution, name: 'APTrust', identifier: 'apt.org'),
                            stub_model(Institution, name: 'University of Virginia', identifier: 'virginia.edu')
                        ])
    controller.stub(:current_user).and_return user
    controller.stub(:sizes).and_return sizes
  end

  describe 'A user with access' do
    before do
      allow(view).to receive(:policy).and_return double(show?: true, edit?: true, create?: true)
      render
    end

    it 'displays the page header' do
      rendered.should have_css('h1', text: 'Institutions')
    end

    it 'has a link to view at least one institution' do
      rendered.should have_link('APTrust', href: institution_path('apt.org'))
    end
  end

  describe 'A user without access' do
    before do
      allow(view).to receive(:policy).and_return double(show?: false, edit?: false, create?: false)
      render
    end

    it 'should not display the links' do
      rendered.should_not have_link('APTrust', href: institution_path('apt.org'))
    end
  end
end