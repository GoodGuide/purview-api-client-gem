module GoodGuide
  module EntitySoup

    class Account
      include Resource

      attributes :name

      def attr_values(params = {})
        AttrValue.find_all(params.merge(account_id: self.id))
      end

      def self.find_by_name(name, opts = {})
        Account.find_all(opts.merge(name: name)).first
      end
    end

  end
end
