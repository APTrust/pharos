require 'spec_helper'

RSpec.describe Institution, :type => :model do
  subject { FactoryGirl.build(:institution) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:identifier) }

  describe '#name_is_unique' do
    it 'should validate uniqueness of the name' do
      one = FactoryGirl.create(:institution, name: 'test')
      two = FactoryGirl.build(:institution, name: 'test')
      two.should_not be_valid
      two.errors[:name].should include('has already been taken')
    end
  end

  describe '#identifier_is_unique' do
    it 'should validate uniqueness of the identifier' do
      one = FactoryGirl.create(:institution, identifier: 'test.edu')
      two = FactoryGirl.build(:institution, identifier: 'test.edu')
      two.should_not be_valid
      two.errors[:identifier].should include('has already been taken')
    end
  end

  describe '#find_by_identifier' do
    it 'should validate uniqueness of the identifier' do
      one = FactoryGirl.create(:institution, identifier: 'test.edu')
      two = FactoryGirl.create(:institution, identifier: 'kollege.edu')
      Institution.find_by_identifier('test.edu').should eq one
      Institution.find_by_identifier('kollege.edu').should eq two
      Institution.find_by_identifier('idontexist.edu').should be nil
    end
  end

  describe 'bytes_by_format' do
    it 'should return a hash' do
      expect(subject.bytes_by_format).to eq({'all'=>0})
    end
    describe 'with attached files' do
      before do
        subject.save!
      end
      let(:intellectual_object) { FactoryGirl.create(:intellectual_object, institution: subject) }
      let!(:generic_file1) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object, size: 166311750, identifier: 'test.edu/123/data/file.xml') }
      let!(:generic_file2) { FactoryGirl.create(:generic_file, intellectual_object: intellectual_object, file_format: 'audio/wav', size: 143732461, identifier: 'test.edu/123/data/file.wav') }
      it 'should return a hash' do
        expect(subject.bytes_by_format).to eq({"all"=>310044211,
                                               'application/xml' => 166311750,
                                               'audio/wav' => 143732461})
      end
    end
  end

  describe 'a saved instance' do
    before do
      subject.save
    end

    after do
      subject.destroy
    end
    describe 'with an associated user' do
      let!(:user) { FactoryGirl.create(:user, name: 'Zeke', institution_id: subject.id)  }
      it 'should contain the appropriate User' do
        subject.users.should eq [user]
      end

      it 'deleting should be blocked' do
        subject.destroy.should be false
        expect(Institution.exists?(subject.id)).to be true
      end

      describe 'or two' do
        let!(:user2) { FactoryGirl.create(:user, name: 'Andrew', institution_id: subject.id) }
        it 'should return users sorted by name' do
          subject.users.index(user).should > subject.users.index(user2)
        end
      end
    end

    describe 'with an associated intellectual object' do
      let!(:item) { FactoryGirl.create(:intellectual_object, institution: subject) }
      after { item.destroy }
      it 'deleting should be blocked' do
        subject.destroy.should be false
        expect(Institution.exists?(subject.id)).to be true
      end
    end
  end
end
