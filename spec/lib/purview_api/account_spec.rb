require "purview_api/account"

describe 'Accounts', :vcr do
  before { PurviewApi.authenticate! }

  describe '.find_all' do
    it 'finds all the accounts' do
      accounts = PurviewApi::Account.find_all

      expect(accounts.length).to be > 1
      expect(accounts.first).to be_a_kind_of(PurviewApi::Account)
    end
  end

  describe '.find' do
    it 'finds the first account' do
      first_account = PurviewApi::Account.find_all.first
      account = PurviewApi::Account.find(first_account.id)

      expect(account.name).to eq(first_account.name)
    end
  end

  describe '.find_by_name' do
    it 'can find an account by name' do
      account = PurviewApi::Account.find_by_name('Target')

      expect(account).to be_a(PurviewApi::Account)
      expect(account.name).to eq('Target')
    end
  end

  describe '.save' do
    context 'with missing arguments' do
      let(:expected_messages) do
        {
          name: [["can't be blank"]],
          company_name: [["can't be blank"]],
        }
      end

      it 'returns the errors' do
        account = PurviewApi::Account.new

        expect(account.save).to be false
        expect(account.errors.messages).to eq(expected_messages)
      end
    end
  end

  describe '.save!' do
    it 'raises an error when save fails' do
      expect {
        PurviewApi::Account.new.save!
      }.to raise_error(PurviewApi::Resource::ResourceNotSaved)
    end
  end
end
