require 'spec_helper'

RSpec.describe IntellectualObject, :type => :model do
  after(:all) do
    IntellectualObject.destroy_all
  end

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:identifier) }
  it { should validate_presence_of(:institution) }
  it { should validate_presence_of(:access)}

  describe 'An instance' do

    it 'should properly set a title' do
      subject.title = 'War and Peace'
      subject.title.should == 'War and Peace'
    end

    it 'should properly set access' do
      subject.access = 'consortia'
      subject.access.should == 'consortia'
    end

    it 'must be one of the standard access' do
      subject.access = 'error'
      subject.should_not be_valid
    end

    it 'should properly set a description' do
      exp = Faker::Lorem.paragraph
      subject.description = exp
      subject.description.should == exp
    end

    it 'should properly set an identifier' do
      exp = SecureRandom.uuid
      subject.identifier = exp
      subject.identifier.should == exp
    end

    it 'should properly set an alternative identifier' do
      exp = 'test.edu/123456'
      subject.alt_identifier = exp
      subject.alt_identifier.should == exp
    end

    it 'should properly set a bag name' do
      exp = 'bag_name'
      subject.bag_name = exp
      subject.bag_name.should == exp
    end

  end

  describe 'permission scopes and checks' do
    let!(:inst) { FactoryGirl.create(:institution) }
    let!(:other_inst) { FactoryGirl.create(:institution) }

    let!(:inst_user) { FactoryGirl.create(:user, :institutional_user,
                                          institution: inst) }
    let!(:inst_admin) { FactoryGirl.create(:user, :institutional_admin,
                                           institution: inst) }
    let!(:sys_admin) { FactoryGirl.create(:user, :admin) }

    let!(:obj_own_consortia) { FactoryGirl.create(:intellectual_object,
                                                  access: 'consortia', institution: inst) }
    let!(:obj_own_inst) { FactoryGirl.create(:intellectual_object,
                                             access: 'institution', institution: inst) }
    let!(:obj_own_restricted) { FactoryGirl.create(:intellectual_object,
                                                   access: 'restricted', institution: inst) }
    let!(:obj_other_consortia) { FactoryGirl.create(:intellectual_object,
                                                    access: 'consortia', institution: other_inst) }
    let!(:obj_other_inst) { FactoryGirl.create(:intellectual_object,
                                               access: 'institution', institution: other_inst) }
    let!(:obj_other_restricted) { FactoryGirl.create(:intellectual_object,
                                                     access: 'restricted', institution: other_inst) }

    # ----------- CONSORTIA --------------

    it 'should let inst user discover consortial item' do
      results = IntellectualObject.discoverable(inst_user)
      expect(results).to include(obj_own_consortia)
      expect(results).to include(obj_other_consortia)
    end

    it 'should let inst admin discover consortial item' do
      results = IntellectualObject.discoverable(inst_admin)
      expect(results).to include(obj_own_consortia)
      expect(results).to include(obj_other_consortia)
    end

    it 'should let sys admin discover consortial item' do
      results = IntellectualObject.discoverable(sys_admin)
      expect(results).to include(obj_own_consortia)
      expect(results).to include(obj_other_consortia)
    end

    it 'should let inst user read own consortial item' do
      results = IntellectualObject.readable(inst_user)
      expect(results).to include(obj_own_consortia)
      expect(results).not_to include(obj_other_consortia)
    end

    it 'should let inst admin read own consortial item' do
      results = IntellectualObject.readable(inst_admin)
      expect(results).to include(obj_own_consortia)
      expect(results).not_to include(obj_other_consortia)
    end

    it 'should let sys admin read any consortial item' do
      results = IntellectualObject.readable(sys_admin)
      expect(results).to include(obj_own_consortia)
      expect(results).to include(obj_other_consortia)
    end

    it 'should not let inst user edit other consortial item' do
      results = IntellectualObject.readable(inst_user)
      expect(results).not_to include(obj_other_consortia)
    end

    it 'should not let inst admin edit other consortial item' do
      results = IntellectualObject.writable(inst_admin)
      expect(results).not_to include(obj_other_consortia)
    end

    it 'should not let inst admin edit any consortial items' do
      results = IntellectualObject.writable(inst_admin)
      expect(results).not_to include(obj_own_consortia)
      expect(results).not_to include(obj_other_consortia)
    end

    it 'should let sys admin edit consortial item' do
      results = IntellectualObject.writable(sys_admin)
      expect(results).to include(obj_own_consortia)
      expect(results).to include(obj_other_consortia)
    end

    # ----------- INSTITUTION --------------

    it 'should let inst user discover own item' do
      results = IntellectualObject.discoverable(inst_user)
      expect(results).to include(obj_own_inst)
    end

    it "should let not inst user discover someone else's item" do
      results = IntellectualObject.discoverable(inst_user)
      expect(results).not_to include(obj_other_inst)
    end

    it 'should let inst user read own item' do
      results = IntellectualObject.readable(inst_user)
      expect(results).to include(obj_own_inst)
    end

    it "should let not inst user read someone else's item" do
      results = IntellectualObject.readable(inst_user)
      expect(results).not_to include(obj_other_inst)
    end

    it 'should let inst admin discover own item' do
      results = IntellectualObject.discoverable(inst_admin)
      expect(results).to include(obj_own_inst)
    end

    it "should not let inst admin discover someone else's item" do
      results = IntellectualObject.discoverable(inst_admin)
      expect(results).not_to include(obj_other_inst)
    end

    it 'should let inst admin read own item' do
      results = IntellectualObject.readable(inst_admin)
      expect(results).to include(obj_own_inst)
    end

    it "should not let inst admin read someone else's item" do
      results = IntellectualObject.readable(inst_admin)
      expect(results).not_to include(obj_other_inst)
    end

    it 'should not let inst user edit own item' do
      results = IntellectualObject.writable(inst_user)
      expect(results).not_to include(obj_own_inst)
    end

    it "should not let inst user edit someone else's item" do
      results = IntellectualObject.writable(inst_user)
      expect(results).not_to include(obj_other_inst)
    end

    it 'should not let inst admin edit own item' do
      results = IntellectualObject.writable(inst_admin)
      expect(results).not_to include(obj_own_inst)
    end

    it "should not let inst admin edit someone else's item" do
      results = IntellectualObject.writable(inst_admin)
      expect(results).not_to include(obj_other_inst)
    end

    it 'should let sys admin discover inst item' do
      results = IntellectualObject.discoverable(sys_admin)
      expect(results).to include(obj_own_inst)
      expect(results).to include(obj_other_inst)
    end

    it 'should let sys admin read inst item' do
      results = IntellectualObject.readable(sys_admin)
      expect(results).to include(obj_own_inst)
      expect(results).to include(obj_other_inst)
    end

    it 'should let sys admin edit inst item' do
      results = IntellectualObject.writable(sys_admin)
      expect(results).to include(obj_own_inst)
      expect(results).to include(obj_other_inst)
    end

    # ----------- RESTRICTED --------------

    it 'should let inst user discover own item' do
      results = IntellectualObject.discoverable(inst_user)
      expect(results).to include(obj_own_restricted)
    end

    it "should not let inst user discover someone else's item" do
      results = IntellectualObject.discoverable(inst_user)
      expect(results).not_to include(obj_other_restricted)
    end

    it 'should not let inst user read own item' do
      results = IntellectualObject.readable(inst_user)
      expect(results).not_to include(obj_own_restricted)
    end

    it "should not let inst user read someone else's item" do
      results = IntellectualObject.readable(inst_user)
      expect(results).not_to include(obj_other_restricted)
    end

    it 'should not let inst user edit own item' do
      results = IntellectualObject.writable(inst_user)
      expect(results).not_to include(obj_own_restricted)
    end

    it "should not let inst user edit someone else's item" do
      results = IntellectualObject.writable(inst_user)
      expect(results).not_to include(obj_other_restricted)
    end

    it 'should let inst admin discover own item' do
      results = IntellectualObject.discoverable(inst_admin)
      expect(results).to include(obj_own_restricted)
    end

    it "should not let inst admin discover other's item" do
      results = IntellectualObject.discoverable(inst_admin)
      expect(results).not_to include(obj_other_restricted)
    end

    it 'should let inst admin read own item' do
      results = IntellectualObject.readable(inst_admin)
      expect(results).to include(obj_own_restricted)
    end

    it "should not let inst admin read other's item" do
      results = IntellectualObject.readable(inst_admin)
      expect(results).not_to include(obj_other_restricted)
    end

    it 'should not let inst admin edit own item' do
      results = IntellectualObject.writable(inst_admin)
      expect(results).not_to include(obj_own_restricted)
    end

    it "should not let inst admin edit someone else's item" do
      results = IntellectualObject.writable(inst_admin)
      expect(results).not_to include(obj_other_restricted)
    end

    it 'should let sys admin discover any item' do
      results = IntellectualObject.discoverable(sys_admin)
      expect(results).to include(obj_own_restricted)
      expect(results).to include(obj_other_restricted)
    end

    it 'should let sys admin read any item' do
      results = IntellectualObject.readable(sys_admin)
      expect(results).to include(obj_own_restricted)
      expect(results).to include(obj_other_restricted)
    end

    it 'should let sys admin edit any item' do
      results = IntellectualObject.writable(sys_admin)
      expect(results).to include(obj_own_restricted)
      expect(results).to include(obj_other_restricted)
    end

  end

  describe 'bytes_by_format' do
    subject { FactoryGirl.create(:institutional_intellectual_object) }
    it 'should return a hash' do
      expect(subject.bytes_by_format).to eq({"all"=>0})
    end

    describe 'with attached files' do
      before do
        subject.generic_files << FactoryGirl.build(:generic_file,
                                                   intellectual_object: subject,
                                                   size: 166311750,
                                                   identifier: 'test.edu/123/data/file.xml')
        subject.generic_files << FactoryGirl.build(:generic_file,
                                                   intellectual_object: subject,
                                                   file_format: 'audio/wav',
                                                   size: 143732461,
                                                   identifier: 'test.edu/123/data/file.wav')
        subject.save!
      end

      it 'should return a hash' do
        expect(subject.bytes_by_format).to eq({'all'=>310044211,
                                               'application/xml' => 166311750,
                                               'audio/wav' => 143732461})
      end
    end
  end

  describe 'A saved instance' do
    after { subject.destroy }

    describe 'with generic files' do
      after do
        subject.generic_files.destroy_all
      end

      subject { FactoryGirl.create(:intellectual_object) }

      before do
        @file = FactoryGirl.create(:generic_file, intellectual_object: subject)
        subject.reload
      end

      it 'test setup assumptions' do
        subject.id.should == subject.generic_files.first.intellectual_object_id
        subject.generic_files.should == [@file]
      end

      it 'should not be destroyable' do
        expect(subject.destroy).to be false
      end

      it 'should fill in an empty bag name with data from the identifier' do
        expect(subject.bag_name).to eq subject.identifier.split('/')[1]
      end

      describe 'soft_delete' do
        before {
          @work_item = FactoryGirl.create(:work_item,
                                          object_identifier: subject.identifier,
                                          action: Pharos::Application::PHAROS_ACTIONS['ingest'],
                                          stage: Pharos::Application::PHAROS_STAGES['record'],
                                          status: Pharos::Application::PHAROS_STATUSES['success'])
        }
        after {
          @work_item.delete
        }
        let(:intellectual_object_delete_job) { double('intellectual object') }
        let(:generic_file_delete_job) { double('file') }

        it 'should set the state to deleted and index the object state' do
          attributes = FactoryGirl.attributes_for(:premis_event_deletion, outcome_detail: 'joe@example.com')
          expect {
            subject.soft_delete(attributes)
          }.to change { subject.premis_events.count}.by(1)
          subject.background_deletion(attributes)
          expect(subject.state).to eq 'D'
          subject.generic_files.all?{ |file| expect(file.state).to eq 'D' }
        end

        it 'should set the state to deleted and index the object state' do
          attributes = FactoryGirl.attributes_for(:premis_event_deletion, outcome_detail: 'user@example.com')
          subject.soft_delete(attributes)
          subject.background_deletion(attributes)
          subject.generic_files.all?{ |file|
            wi = WorkItem.where(generic_file_identifier: file.identifier).first
            expect(wi).not_to be_nil
            expect(wi.object_identifier).to eq subject.identifier
            expect(wi.action).to eq Pharos::Application::PHAROS_ACTIONS['delete']
            expect(wi.stage).to eq Pharos::Application::PHAROS_STAGES['requested']
            expect(wi.status).to eq Pharos::Application::PHAROS_STATUSES['pend']
            expect(wi.user).to eq 'user@example.com'
          }
        end

      end
    end

    describe 'unique identifier' do
      let(:inst_id) { subject.institution.id }
      describe '#identifier_is_unique' do
        it 'should validate uniqueness of the identifier' do
          one = FactoryGirl.create(:intellectual_object, identifier: 'test.edu/234')
          two = FactoryGirl.build(:intellectual_object, identifier: 'test.edu/234')
          two.should_not be_valid
          two.errors[:identifier].should include('has already been taken')
        end
      end
    end

    describe 'scopes by attribute' do
      let!(:inst) { FactoryGirl.create(:institution) }
      let!(:other_inst) { FactoryGirl.create(:institution) }

      let!(:inst_admin) { FactoryGirl.create(:user, :institutional_admin,
                                             institution: inst) }
      let!(:obj1) { FactoryGirl.create(:intellectual_object,
                                       institution: inst,
                                       identifier: 'test.edu/first',
                                       alt_identifier: 'first alt identifier',
                                       created_at: '2011-01-01',
                                       updated_at: '2011-01-01',
                                       description: 'Description of first item',
                                       bag_name: 'first_item',
                                       title: 'Title of first item',
                                       state: 'A') }
      let!(:obj2) { FactoryGirl.create(:intellectual_object,
                                       institution: inst,
                                       identifier: 'test.edu/second',
                                       alt_identifier: 'second alt identifier',
                                       created_at: '2017-01-01',
                                       updated_at: '2017-01-01',
                                       description: 'Description of second item',
                                       bag_name: 'second_item',
                                       title: 'Title of second item',
                                       state: 'A') }
      let!(:obj3) { FactoryGirl.create(:intellectual_object,
                                       institution: other_inst,
                                       identifier: 'xxx',
                                       alt_identifier: 'xxx',
                                       created_at: '2016-01-01',
                                       updated_at: '2016-01-01',
                                       description: 'xxx',
                                       bag_name: 'xxx',
                                       title: 'xxx',
                                       state: 'D') }

      it 'should find items created before' do
        results = IntellectualObject.created_before('2016-07-29')
        expect(results).to include obj1
        expect(results).to include obj3
        expect(results.count).to eq 2
      end

      it 'should find items created after' do
        results = IntellectualObject.created_after('2016-07-29')
        expect(results).to include obj2
        expect(results.count).to eq 1
      end

      it 'should find items updated before' do
        results = IntellectualObject.updated_before('2016-07-29')
        expect(results).to include obj1
        expect(results).to include obj3
        expect(results.count).to eq 2
      end

      it 'should find items updated after' do
        results = IntellectualObject.updated_after('2016-07-29')
        expect(results).to include obj2
        expect(results.count).to eq 1
      end

      it 'should find items with description' do
        results = IntellectualObject.with_description('Description of first item')
        expect(results).to include obj1
        expect(results.count).to eq 1
      end

      it 'should find items with description like' do
        results = IntellectualObject.with_description_like('first')
        expect(results).to include obj1
        expect(results.count).to eq 1
        results = IntellectualObject.with_description_like('item')
        expect(results).to include obj1
        expect(results).to include obj2
        expect(results.count).to eq 2
      end

      it 'should find items with identifier' do
        results = IntellectualObject.with_identifier('test.edu/first')
        expect(results).to include obj1
        expect(results.count).to eq 1
      end

      it 'should find items with identifier like' do
        results = IntellectualObject.with_identifier_like('first')
        expect(results).to include obj1
        expect(results.count).to eq 1
      end

      it 'should find items with alt identifier' do
        results = IntellectualObject.with_alt_identifier('first alt identifier')
        expect(results).to include obj1
        expect(results.count).to eq 1
      end

      it 'should find items with alt identifier like' do
        results = IntellectualObject.with_alt_identifier_like('alt ident')
        expect(results).to include obj1
        expect(results).to include obj2
        expect(results.count).to eq 2
      end

      it 'should find items with institution' do
        results = IntellectualObject.with_institution(inst)
        expect(results).to include obj1
        expect(results).to include obj2
        expect(results.count).to eq 2
      end

      it 'should find items with state' do
        results = IntellectualObject.with_state('A')
        expect(results).to include obj1
        expect(results).to include obj2
        expect(results.count).to eq 2
        results = IntellectualObject.with_state('D')
        expect(results).to include obj3
        expect(results.count).to eq 1
      end

      it 'should find items with bag name like' do
        results = IntellectualObject.with_bag_name_like('first')
        expect(results).to include obj1
        expect(results.count).to eq 1
        results = IntellectualObject.with_bag_name_like('item')
        expect(results).to include obj1
        expect(results).to include obj2
        expect(results.count).to eq 2
      end

      it 'should find items with title like' do
        results = IntellectualObject.with_title_like('first')
        expect(results).to include obj1
        expect(results.count).to eq 1
        results = IntellectualObject.with_title_like('item')
        expect(results).to include obj1
        expect(results).to include obj2
        expect(results.count).to eq 2
      end

      it 'should allow chained scopes' do
        results = IntellectualObject
          .created_before('2016-01-01')
          .updated_before('2016-01-01')
          .with_identifier_like('edu')
          .with_description_like('item')
          .with_title_like('item')
          .with_state('A')
          .readable(inst_admin)
        expect(results).to include obj1
        expect(results.count).to eq 1
      end

    end
  end

  describe '#find_by_identifier' do
    let(:subject) { FactoryGirl.create(:intellectual_object, identifier: 'abc.edu/123') }
    let(:subject_two) { FactoryGirl.create(:intellectual_object, identifier: 'xyz.edu/789') }
    it 'should find by identifier' do
      subject.save!
      subject_two.save!
      obj1 = IntellectualObject.find_by_identifier('abc.edu/123')
      expect(obj1).to eq subject
      obj1 = IntellectualObject.find_by_identifier('abc.edu%2f123')
      expect(obj1).to eq subject
      obj1 = IntellectualObject.find_by_identifier('abc.edu%2F123')
      expect(obj1).to eq subject
      obj2 = IntellectualObject.find_by_identifier('xyz.edu/789')
      expect(obj2).to eq subject_two
      obj2 = IntellectualObject.find_by_identifier('i_dont_exist')
      expect(obj2).to be_nil
    end
  end

end
