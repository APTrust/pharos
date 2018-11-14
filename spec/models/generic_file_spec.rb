require 'spec_helper'

RSpec.describe GenericFile, :type => :model do

  it 'delegates institution to the intellectual object' do
    file = FactoryBot.create(:generic_file)
    institution = file.intellectual_object.institution
    file.institution.should == institution
  end

  it { should validate_presence_of(:uri) }
  it { should validate_presence_of(:size) }
  it { should validate_presence_of(:file_format) }
  it { should validate_presence_of(:identifier) }
  it { should validate_presence_of(:institution_id) }
  it { should validate_presence_of(:storage_option) }

  it 'should validate presence of intellectual object' do
    file = FactoryBot.create(:generic_file)
    expect(file.intellectual_object).to be_valid
    expect(file.intellectual_object.identifier).to include('/')
  end

  it 'should not allow the institution_id to be changed once set' do
    file = FactoryBot.create(:generic_file)
    file.institution_id = 15
    file.save!
    file.errors[:institution_id].should include('cannot be changed')
  end

  it 'should not allow the storage_option to be changed once set' do
    file = FactoryBot.create(:generic_file)
    file.storage_option = 'Glacier-OH'
    file.save!
    file.errors[:storage_option].should include('cannot be changed')
  end

  it 'should accept an identifier that is longer than 256 characters' do
    file = FactoryBot.create(:generic_file, identifier: 'somethingoutrageous.edu/a_very_very_crazy_long_bag_name_full_of_photos-3453443509-139862-3459u350984/data/this_file_needs_to_be_super_long/something_extra/way_down_deep/defying_gravity/out_of_ideas/13948098712349-34982309857923-239872989298745-2093809609864320940-2349869432098459082.txt')
    expect(file.identifier).to eq 'somethingoutrageous.edu/a_very_very_crazy_long_bag_name_full_of_photos-3453443509-139862-3459u350984/data/this_file_needs_to_be_super_long/something_extra/way_down_deep/defying_gravity/out_of_ideas/13948098712349-34982309857923-239872989298745-2093809609864320940-2349869432098459082.txt'
  end

  describe '#identifier_is_unique' do
    it 'should validate uniqueness of the identifier' do
      one = FactoryBot.create(:generic_file, identifier: 'test.edu')
      two = FactoryBot.build(:generic_file, identifier: 'test.edu')
      two.should_not be_valid
      two.errors[:identifier].should include('has already been taken')
    end
  end

  describe 'with an intellectual object' do
    before do
      subject.intellectual_object = intellectual_object
    end

    let(:institution) { mock_model Institution, internal_uri: 'info:fedora/testing:123', name: 'Mock Name' }
    let(:intellectual_object) { mock_model IntellectualObject, institution: institution, identifier: 'info:fedora/testing:123/1234567' }

    describe '#last_fixity_check' do
      subject { FactoryBot.create(:generic_file) }
      it 'should return the most recent fixity check' do
        date = '2014-08-01T16:33:39Z'
        date_two = '2014-10-01T16:33:39Z'
        date_three = '2014-11-01T16:33:39Z'
        subject.add_event(FactoryBot.attributes_for(:premis_event_fixity_check, date_time: date))
        subject.last_fixity_check.should == date

        subject.add_event(FactoryBot.attributes_for(:premis_event_fixity_check, date_time: date_two))
        subject.last_fixity_check.should == date_two

        subject.add_event(FactoryBot.attributes_for(:premis_event_fixity_check, date_time: date_three))
        subject.last_fixity_check.should == date_three
      end
    end

    describe 'that is saved' do
      let(:intellectual_object) { FactoryBot.create(:intellectual_object) }
      subject { FactoryBot.create(:generic_file, intellectual_object: intellectual_object) }
      describe 'its intellectual_object' do
        after(:all)do # Must use after(:all) to avoid 'can't modify frozen Class' bug in rspec-mocks
          subject.destroy
          intellectual_object.destroy
        end
      end

      describe 'soft_delete' do
        let(:object) { FactoryBot.create(:intellectual_object) }
        let(:file) { FactoryBot.create(:generic_file, intellectual_object: object) }
        before do
          file.save!
          @parent_work_item = FactoryBot.create(:work_item,
                                                      object_identifier: file.intellectual_object.identifier,
                                                      action: Pharos::Application::PHAROS_ACTIONS['ingest'],
                                                      stage: Pharos::Application::PHAROS_STAGES['record'],
                                                      status: Pharos::Application::PHAROS_STATUSES['success'])
        end
        after do
          file.destroy
          intellectual_object.delete
          @parent_work_item.delete
        end

        let(:async_job) { double('one') }

        it 'should set the state to deleted and index the object state' do
          attributes = { requestor: 'user@example.com',
                         inst_app: 'other_user@example.com' }
          expect {
            # A.D. 1/29/2017: Don't create the file delete event.
            # Let the Go services code do that when the actual
            # deletion occurs.
            file.soft_delete(attributes)
          }.to change { file.premis_events.count}.by(0)
          expect(file.state).to eq 'A' # no longer marked as deleted until final step
        end

        it 'should create a WorkItem showing delete was requested' do
          attributes = { requestor: 'user@example.com',
                         inst_app: 'other_user@example.com' }
          file.soft_delete(attributes)
          pi = WorkItem.where(generic_file_identifier: file.identifier).first
          expect(pi).not_to be_nil
          expect(pi.object_identifier).to eq file.intellectual_object.identifier
          expect(pi.action).to eq Pharos::Application::PHAROS_ACTIONS['delete']
          expect(pi.stage).to eq Pharos::Application::PHAROS_STAGES['requested']
          expect(pi.status).to eq Pharos::Application::PHAROS_STATUSES['pend']
          expect(pi.user).to eq 'user@example.com'
          expect(pi.inst_approver).to eq 'other_user@example.com'
        end

      end

      describe 'serializable_hash' do
        let(:subject) { FactoryBot.create(:generic_file) }
        before do
        end
        after do
        end

        it 'should set the state to deleted and index the object state' do
          h1 = subject.serializable_hash
          expect(h1.has_key?('id')).to be true
          expect(h1.has_key?('uri')).to be true
          expect(h1.has_key?('size')).to be true
          expect(h1.has_key?('created_at')).to be true
          expect(h1.has_key?('updated_at')).to be true
          expect(h1.has_key?('file_format')).to be true
          expect(h1.has_key?('identifier')).to be true
          expect(h1.has_key?('state')).to be true
          expect(h1.has_key?('intellectual_object_identifier')).to be true
          expect(h1.has_key?('institution_id')).to be true
          expect(h1.has_key?('storage_option')).to be true

          h2 = subject.serializable_hash(include: [:checksums, :premis_events, :ingest_state])
          expect(h2.has_key?('id')).to be true
          expect(h2.has_key?('uri')).to be true
          expect(h2.has_key?('size')).to be true
          expect(h2.has_key?('created_at')).to be true
          expect(h2.has_key?('updated_at')).to be true
          expect(h2.has_key?('file_format')).to be true
          expect(h2.has_key?('identifier')).to be true
          expect(h2.has_key?('state')).to be true
          expect(h2.has_key?('checksums')).to be true
          expect(h2.has_key?('premis_events')).to be true
          expect(h2.has_key?('intellectual_object_identifier')).to be true
          expect(h2.has_key?('ingest_state')).to be true
          expect(h1.has_key?('institution_id')).to be true
          expect(h1.has_key?('storage_option')).to be true
        end
      end

      describe 'find_checksum_by_digest' do
        it 'should find the checksum' do
          subject.checksums.push(FactoryBot.create(:checksum))
          digest = subject.checksums.first.digest
          expect(subject.find_checksum_by_digest(digest)).not_to be_nil
        end
        it 'should return nil for non-existent checksum' do
          expect(subject.find_checksum_by_digest(' :-{ ')).to be_nil
        end
      end

      describe 'has_checksum?' do
        it 'should return true if checksum is present' do
          subject.checksums.push(FactoryBot.create(:checksum))
          digest = subject.checksums.first.digest
          expect(subject.has_checksum?(digest)).to be true
        end
        it 'should return false if checksum is not present' do
          expect(subject.has_checksum?(' :( ')).to be false
        end
      end

    end
  end

  describe '#not_checked_since' do
    before do
      PremisEvent.delete_all
      GenericFile.delete_all
    end
    it 'should return only files that have not had a fixity check since the given date' do
      dates = ['2017-01-01T00:00:00Z', '2016-01-01T00:00:00Z', '2015-01-01T00:00:00Z']
      10.times do |i|
        gf = FactoryBot.create(:generic_file, state: 'A')
        event = gf.add_event(FactoryBot.attributes_for(:premis_event_fixity_check, date_time: dates[i % 3]))
      end
      files = GenericFile.not_checked_since('2015-01-01T00:00:00Z')
      files.count.should == 3
      files = GenericFile.not_checked_since('2016-01-01T00:00:00Z')
      files.count.should == 6
      files = GenericFile.not_checked_since('2017-01-01T00:00:00Z')
      files.count.should == 10
    end
  end

  describe '#find_by_identifier' do
    let(:subject) { FactoryBot.create(:generic_file, identifier: 'abc/123') }
    let(:subject_two) { FactoryBot.create(:generic_file, identifier: 'xyz/789') }
    it 'should find by identifier' do
      subject.save!
      subject_two.save!
      gf1 = GenericFile.find_by_identifier('abc/123')
      expect(gf1).to eq subject
      gf1 = GenericFile.find_by_identifier('abc%2f123')
      expect(gf1).to eq subject
      gf1 = GenericFile.find_by_identifier('abc%2F123')
      expect(gf1).to eq subject
      gf2 = GenericFile.find_by_identifier('xyz/789')
      expect(gf2).to eq subject_two
      gf2 = GenericFile.find_by_identifier('i_dont_exist')
      expect(gf2).to be_nil
    end
  end

  describe '#deleted_since_last_ingest?' do
    subject { FactoryBot.create(:generic_file) }
    it 'should not say item is deleted if no deletion event since last ingest event' do
      early_date = '2014-06-01T16:33:39Z'
      middle_date = '2014-08-01T16:33:39Z'
      late_date = '2014-10-01T16:33:39Z'
      subject.add_event(FactoryBot.attributes_for(:premis_event_ingest, date_time: middle_date))
      subject.premis_events.where(event_type: Pharos::Application::PHAROS_EVENT_TYPES['ingest']).first.date_time.should == middle_date
      # False because there is no delete event.
      expect(subject.deleted_since_last_ingest?).to eq false

      subject.add_event(FactoryBot.attributes_for(:premis_event_deletion, date_time: early_date))
      subject.premis_events.where(event_type: Pharos::Application::PHAROS_EVENT_TYPES['delete']).order(date_time: :desc).first.date_time.should == early_date
      # False because deletion came BEFORE most recent ingest.
      expect(subject.deleted_since_last_ingest?).to eq false
    end
  end

  describe '#deleted_since_last_ingest?' do
    subject { FactoryBot.create(:generic_file) }
    it 'should say item is deleted if this is a deletion event since last ingest event' do
      early_date = '2014-06-01T16:33:39Z'
      middle_date = '2014-08-01T16:33:39Z'
      late_date = '2014-10-01T16:33:39Z'
      # Add ingest event with middle date
      subject.add_event(FactoryBot.attributes_for(:premis_event_ingest, date_time: middle_date))
      subject.premis_events.where(event_type: Pharos::Application::PHAROS_EVENT_TYPES['ingest']).first.date_time.should == middle_date
      # Add deletion event with late date
      subject.add_event(FactoryBot.attributes_for(:premis_event_deletion, date_time: late_date))
      subject.premis_events.where(event_type: Pharos::Application::PHAROS_EVENT_TYPES['delete']).order(date_time: :desc).first.date_time.should == late_date
      # True because deletion came AFTER most recent ingest.
      expect(subject.deleted_since_last_ingest?).to eq true
    end
  end

  describe 'permission scopes and checks' do
    let!(:inst) { FactoryBot.create(:member_institution) }
    let!(:other_inst) { FactoryBot.create(:subscription_institution) }

    let!(:inst_user) { FactoryBot.create(:user, :institutional_user,
                                          institution: inst) }
    let!(:inst_admin) { FactoryBot.create(:user, :institutional_admin,
                                           institution: inst) }
    let!(:sys_admin) { FactoryBot.create(:user, :admin) }

    let!(:obj_own_consortia) { FactoryBot.create(:intellectual_object,
                                                  access: 'consortia', institution: inst) }
    let!(:gf_own_consortia) { FactoryBot.create(:generic_file, intellectual_object: obj_own_consortia) }
    let!(:obj_own_inst) { FactoryBot.create(:intellectual_object,
                                             access: 'institution', institution: inst) }
    let!(:gf_own_inst) { FactoryBot.create(:generic_file, intellectual_object: obj_own_inst) }
    let!(:obj_own_restricted) { FactoryBot.create(:intellectual_object,
                                                   access: 'restricted', institution: inst) }
    let!(:gf_own_restricted) { FactoryBot.create(:generic_file, intellectual_object: obj_own_restricted) }
    let!(:obj_other_consortia) { FactoryBot.create(:intellectual_object,
                                                    access: 'consortia', institution: other_inst) }
    let!(:gf_other_consortia) { FactoryBot.create(:generic_file, intellectual_object: obj_other_consortia) }
    let!(:obj_other_inst) { FactoryBot.create(:intellectual_object,
                                               access: 'institution', institution: other_inst) }
    let!(:gf_other_inst) { FactoryBot.create(:generic_file, intellectual_object: obj_other_inst) }
    let!(:obj_other_restricted) { FactoryBot.create(:intellectual_object,
                                                     access: 'restricted', institution: other_inst) }
    let!(:gf_other_restricted) { FactoryBot.create(:generic_file, intellectual_object: obj_other_restricted) }

    # ----------- CONSORTIA --------------

    it 'should let inst user discover consortial file' do
      results = GenericFile.discoverable(inst_user)
      expect(results).to include(gf_own_consortia)
      expect(results).not_to include(gf_other_consortia)
    end

    it 'should let inst admin discover consortial file' do
      results = GenericFile.discoverable(inst_admin)
      expect(results).to include(gf_own_consortia)
      expect(results).not_to include(gf_other_consortia)
    end

    it 'should let sys admin discover consortial file' do
      results = GenericFile.discoverable(sys_admin)
      expect(results).to include(gf_own_consortia)
      expect(results).to include(gf_other_consortia)
    end

    it 'should let inst user read own consortial file' do
      results = GenericFile.readable(inst_user)
      expect(results).to include(gf_own_consortia)
      expect(results).not_to include(gf_other_consortia)
    end

    it 'should let inst admin read own consortial file' do
      results = GenericFile.readable(inst_admin)
      expect(results).to include(gf_own_consortia)
      expect(results).not_to include(gf_other_consortia)
    end

    it 'should let sys admin read any consortial file' do
      results = GenericFile.readable(sys_admin)
      expect(results).to include(gf_own_consortia)
      expect(results).to include(gf_other_consortia)
    end

    it 'should not let inst user edit other consortial file' do
      results = GenericFile.readable(inst_user)
      expect(results).not_to include(gf_other_consortia)
    end

    it 'should not let inst admin edit other consortial file' do
      results = GenericFile.writable(inst_admin)
      expect(results).not_to include(gf_other_consortia)
    end

    it 'should not let inst admin edit any consortial files' do
      results = GenericFile.writable(inst_admin)
      expect(results).not_to include(gf_own_consortia)
      expect(results).not_to include(gf_other_consortia)
    end

    it 'should let sys admin edit consortial file' do
      results = GenericFile.writable(sys_admin)
      expect(results).to include(gf_own_consortia)
      expect(results).to include(gf_other_consortia)
    end

    # ----------- INSTITUTION --------------

    it 'should let inst user discover own file' do
      results = GenericFile.discoverable(inst_user)
      expect(results).to include(gf_own_inst)
    end

    it "should let not inst user discover someone else's file" do
      results = GenericFile.discoverable(inst_user)
      expect(results).not_to include(gf_other_inst)
    end

    it 'should let inst user read own file' do
      results = GenericFile.readable(inst_user)
      expect(results).to include(gf_own_inst)
    end

    it "should let not inst user read someone else's file" do
      results = GenericFile.readable(inst_user)
      expect(results).not_to include(gf_other_inst)
    end

    it 'should let inst admin discover own file' do
      results = GenericFile.discoverable(inst_admin)
      expect(results).to include(gf_own_inst)
    end

    it "should not let inst admin discover someone else's file" do
      results = GenericFile.discoverable(inst_admin)
      expect(results).not_to include(gf_other_inst)
    end

    it 'should let inst admin read own file' do
      results = GenericFile.readable(inst_admin)
      expect(results).to include(gf_own_inst)
    end

    it "should not let inst admin read someone else's file" do
      results = GenericFile.readable(inst_admin)
      expect(results).not_to include(gf_other_inst)
    end

    it 'should not let inst user edit own file' do
      results = GenericFile.writable(inst_user)
      expect(results).not_to include(gf_own_inst)
    end

    it "should not let inst user edit someone else's file" do
      results = GenericFile.writable(inst_user)
      expect(results).not_to include(gf_other_inst)
    end

    it 'should not let inst admin edit own file' do
      results = GenericFile.writable(inst_admin)
      expect(results).not_to include(gf_own_inst)
    end

    it "should not let inst admin edit someone else's file" do
      results = GenericFile.writable(inst_admin)
      expect(results).not_to include(gf_other_inst)
    end

    it 'should let sys admin discover inst file' do
      results = GenericFile.discoverable(sys_admin)
      expect(results).to include(gf_own_inst)
      expect(results).to include(gf_other_inst)
    end

    it 'should let sys admin read inst file' do
      results = GenericFile.readable(sys_admin)
      expect(results).to include(gf_own_inst)
      expect(results).to include(gf_other_inst)
    end

    it 'should let sys admin edit inst file' do
      results = GenericFile.writable(sys_admin)
      expect(results).to include(gf_own_inst)
      expect(results).to include(gf_other_inst)
    end

    # ----------- RESTRICTED --------------

    it 'should let inst user discover own file' do
      results = GenericFile.discoverable(inst_user)
      expect(results).to include(gf_own_restricted)
    end

    it "should not let inst user discover someone else's file" do
      results = GenericFile.discoverable(inst_user)
      expect(results).not_to include(gf_other_restricted)
    end

    it 'should not let inst user read own file' do
      results = GenericFile.readable(inst_user)
      expect(results).not_to include(gf_own_restricted)
    end

    it "should not let inst user read someone else's file" do
      results = GenericFile.readable(inst_user)
      expect(results).not_to include(gf_other_restricted)
    end

    it 'should not let inst user edit own file' do
      results = GenericFile.writable(inst_user)
      expect(results).not_to include(gf_own_restricted)
    end

    it "should not let inst user edit someone else's file" do
      results = GenericFile.writable(inst_user)
      expect(results).not_to include(gf_other_restricted)
    end

    it 'should let inst admin discover own file' do
      results = GenericFile.discoverable(inst_admin)
      expect(results).to include(gf_own_restricted)
    end

    it "should not let inst admin discover other's file" do
      results = GenericFile.discoverable(inst_admin)
      expect(results).not_to include(gf_other_restricted)
    end

    it 'should let inst admin read own file' do
      results = GenericFile.readable(inst_admin)
      expect(results).to include(gf_own_restricted)
    end

    it "should not let inst admin read other's file" do
      results = GenericFile.readable(inst_admin)
      expect(results).not_to include(gf_other_restricted)
    end

    it 'should not let inst admin edit own file' do
      results = GenericFile.writable(inst_admin)
      expect(results).not_to include(gf_own_restricted)
    end

    it "should not let inst admin edit someone else's file" do
      results = GenericFile.writable(inst_admin)
      expect(results).not_to include(gf_other_restricted)
    end

    it 'should let sys admin discover any file' do
      results = GenericFile.discoverable(sys_admin)
      expect(results).to include(gf_own_restricted)
      expect(results).to include(gf_other_restricted)
    end

    it 'should let sys admin read any file' do
      results = GenericFile.readable(sys_admin)
      expect(results).to include(gf_own_restricted)
      expect(results).to include(gf_other_restricted)
    end

    it 'should let sys admin edit any file' do
      results = GenericFile.writable(sys_admin)
      expect(results).to include(gf_own_restricted)
      expect(results).to include(gf_other_restricted)
    end
  end

  describe 'scopes by attribute' do
    let!(:inst) { FactoryBot.create(:member_institution) }
    let!(:other_inst) { FactoryBot.create(:subscription_institution) }

    let!(:inst_admin) { FactoryBot.create(:user, :institutional_admin,
                                           institution: inst) }
    let!(:obj1) { FactoryBot.create(:intellectual_object,
                                     institution: inst,
                                     identifier: 'test.edu/first',
                                     alt_identifier: 'first alt identifier',
                                     created_at: '2011-01-01',
                                     updated_at: '2011-01-01',
                                     description: 'Description of first item',
                                     bag_name: 'first_item',
                                     title: 'Title of first item',
                                     state: 'A') }
    let!(:obj2) { FactoryBot.create(:intellectual_object,
                                     institution: inst,
                                     identifier: 'test.edu/second',
                                     alt_identifier: 'second alt identifier',
                                     created_at: '2017-01-01',
                                     updated_at: '2017-01-01',
                                     description: 'Description of second item',
                                     bag_name: 'second_item',
                                     title: 'Title of second item',
                                     state: 'A') }
    let!(:obj3) { FactoryBot.create(:intellectual_object,
                                     institution: other_inst,
                                     identifier: 'xxx',
                                     alt_identifier: 'xxx',
                                     created_at: '2016-01-01',
                                     updated_at: '2016-01-01',
                                     description: 'xxx',
                                     bag_name: 'xxx',
                                     title: 'xxx',
                                     state: 'D') }
    let!(:gf1) { FactoryBot.create(:generic_file,
                                    intellectual_object: obj1,
                                    uri: "https://s3.kom/uri1",
                                    identifier: 'test.edu/bag/first',
                                    file_format: 'text/plain',
                                    created_at: '2011-01-01',
                                    updated_at: '2011-01-01',
                                    state: 'A') }
    let!(:gf2) { FactoryBot.create(:generic_file,
                                    intellectual_object: obj2,
                                    uri: "https://s3.kom/uri2",
                                    identifier: 'test.edu/bag/second',
                                    file_format: 'application/pdf',
                                    created_at: '2017-12-31',
                                    updated_at: '2017-12-31',
                                    state: 'A') }
    let!(:gf3) { FactoryBot.create(:generic_file,
                                    intellectual_object: obj3,
                                    uri: "https://s3.kom/uri2",
                                    identifier: 'test.edu/bag/third',
                                    file_format: 'application/xml',
                                    created_at: '2011-01-01',
                                    updated_at: '2011-01-01',
                                    state: 'D') }

    it 'should find items created before' do
      results = GenericFile.created_before('2016-07-29')
      expect(results).to include gf1
      expect(results).to include gf3
      expect(results.count).to eq 2
    end

    it 'should find items created after' do
      results = GenericFile.created_after('2016-07-29')
      expect(results).to include gf2
      expect(results.count).to eq 1
    end

    it 'should find items updated before' do
      results = GenericFile.updated_before('2016-07-29')
      expect(results).to include gf1
      expect(results).to include gf3
      expect(results.count).to eq 2
    end

    it 'should find items updated after' do
      results = GenericFile.updated_after('2016-07-29')
      expect(results).to include gf2
      expect(results.count).to eq 1
    end

    it 'should find items with identifier' do
      results = GenericFile.with_identifier('test.edu/bag/first')
      expect(results).to include gf1
      expect(results.count).to eq 1
    end

    it 'should find items with identifier like' do
      results = GenericFile.with_identifier_like('first')
      expect(results).to include gf1
      expect(results.count).to eq 1
    end

    it 'should find items with state' do
      results = GenericFile.with_state('A')
      expect(results).to include gf1
      expect(results).to include gf2
      expect(results.count).to eq 2
      results = GenericFile.with_state('D')
      expect(results).to include gf3
      expect(results.count).to eq 1
    end

    it 'should find items with institution' do
      results = GenericFile.with_institution(inst)
      expect(results).to include gf1
      expect(results).to include gf2
      expect(results.count).to eq 2
      results = GenericFile.with_institution(other_inst)
      expect(results).to include gf3
      expect(results.count).to eq 1
    end

    it 'should find items with file format' do
      results = GenericFile.with_file_format('text/plain')
      expect(results).to include gf1
      expect(results.count).to eq 1
      results = GenericFile.with_file_format('application/xml')
      expect(results).to include gf3
      expect(results.count).to eq 1
    end

    it 'should allow chained scopes' do
      results = GenericFile
        .created_before('2016-01-01')
        .updated_before('2016-01-01')
        .with_identifier_like('edu')
        .with_file_format('text/plain')
        .with_state('A')
        .with_institution(inst)
        .readable(inst_admin)
      expect(results).to include gf1
      expect(results.count).to eq 1
    end

  end
end
