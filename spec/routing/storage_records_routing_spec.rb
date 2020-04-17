require "spec_helper"

RSpec.describe StorageRecordsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "api/v2/storage_records/apt.org%2F123%2Fdata%2Ffilename.xml").to route_to({"controller"=>"storage_records", "action"=>"index", "generic_file_identifier"=>"apt.org/123/data/filename.xml"})
    end

    # Note that all the tests below are "should NOT route to"

    it "routes to #new" do
      expect(get: "/storage_records/new").not_to route_to("storage_records#new")
    end

    it "routes to #show" do
      expect(get: "/storage_records/1").not_to route_to("storage_records#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/storage_records/1/edit").not_to route_to("storage_records#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/storage_records").not_to route_to("storage_records#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/storage_records/1").not_to route_to("storage_records#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/storage_records/1").not_to route_to("storage_records#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/storage_records/1").not_to route_to("storage_records#destroy", id: "1")
    end
  end
end
