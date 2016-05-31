require "purview_api/resource"

module PurviewApi
  class Account
    include Resource

    define_attribute_methods(:name)

    def self.find_by_name(name)
      # Purview no longer supports matching an account attribute such as:
      # Account.find_all(name: name ).first
      #
      # We'll be happy with this for now
      find_all.detect { |a| a.name == name }
    end
  end
end
