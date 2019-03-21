module Truemail
  RSpec.shared_examples 'sets default configuration' do
    it 'sets default configuration settings' do
      expect(configuration_instance.email_pattern).to be_an_instance_of(Regexp)
      expect(configuration_instance.verifier_email).to be_nil
      expect(configuration_instance.verifier_domain).to be_nil
      expect(configuration_instance.connection_timeout).to eq(Truemail::Configuration::DEFAULT_CONNECTION_TIMEOUT)
      expect(configuration_instance.response_timeout).to eq(Truemail::Configuration::DEFAULT_RESPONSE_TIMEOUT)
      expect(configuration_instance.validation_type_by_domain).to eq({})
    end
  end
end
