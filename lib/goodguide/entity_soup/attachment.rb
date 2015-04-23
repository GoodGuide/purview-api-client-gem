require 'hashie/mash'
module GoodGuide
  module EntitySoup
    class Attachment
      include Resource
      attributes :remote_file_url
    end
  end
end
