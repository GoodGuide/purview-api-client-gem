require 'hashie/mash'

module PurviewApi
  class Attachment
    include Resource

    attributes :remote_file_url
  end
end
