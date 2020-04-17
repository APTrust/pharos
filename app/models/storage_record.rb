# StorageRecord contains a URL pointing to a location in preservation
# storage the contains a GenericFile. The format of these URLs is:
#
# https://<provider_host>/<bucket>/<uuid>
#
# The last part of the URL is the UUID of the GenericFile.
#
# Most files will have 1-2 StorageRecords.
#
# StorageRecords are created and deleted through the GenericFilesController.
# The StorageRecords controller includes only an #index endpoint for use
# by preservation-services workers.
#
# When we delete StorageRecords, we fully delete the records instead of
# just marking them with State='D'. The PremisEvents table contains records
# of deletions that can serve as tombstones.
class StorageRecord < ApplicationRecord
  belongs_to :generic_file

  validates_presence_of :url
  validates_uniqueness_of :url

end
