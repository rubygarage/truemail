# frozen_string_literal: true

RSpec.describe Truemail::Log::Serializer::ValidatorText do
  describe 'defined constants' do
    specify { expect(described_class).to be_const_defined(:ATTEMPT) }
  end

  describe 'inheritance' do
    specify { expect(described_class).to be < Truemail::Log::Serializer::ValidatorBase }
  end

  describe '.call' do
    subject(:text_serializer) { described_class.call(validator_instance) }

    let(:email) { random_email }
    let(:mx_servers) { create_servers_list }
    let(:validator_instance) { create_validator(validation_type, email, mx_servers, success: success_status) }

    shared_examples 'formatted text output' do
      it 'returns formatted text output' do
        expect(text_serializer).to eq(expected_output)
      end
    end

    context 'with successful validation result' do
      let(:success_status)  { true }
      let(:expected_output) do
        <<~EXPECTED_OUTPUT
          Truemail #{validation_type} validation for #{email} was successful

          CONFIGURATION SETTINGS:
          whitelist validation: false
          not rfc mx lookup flow: false
          smtp fail fast: false
          smtp safe check: false
          email pattern: default gem value
          smtp error body pattern: default gem value
        EXPECTED_OUTPUT
      end

      describe 'whitelist validation' do
        let(:validation_type) { :whitelist }
        let(:expected_output) do
          <<~EXPECTED_OUTPUT
            Truemail #{validation_type} validation for #{email} was successful

            CONFIGURATION SETTINGS:
            whitelist validation: false
            whitelisted domains: #{email[Truemail::RegexConstant::REGEX_EMAIL_PATTERN, 3]}
            not rfc mx lookup flow: false
            smtp fail fast: false
            smtp safe check: false
            email pattern: default gem value
            smtp error body pattern: default gem value
          EXPECTED_OUTPUT
        end

        include_examples 'formatted text output'
      end

      describe 'regex validation' do
        let(:validation_type) { :regex }

        include_examples 'formatted text output'
      end

      describe 'mx validation' do
        let(:validation_type) { :mx }

        include_examples 'formatted text output'
      end

      describe 'smtp validation' do
        let(:validation_type) { :smtp }

        include_examples 'formatted text output'
      end
    end

    context 'with fail validation result' do
      let(:success_status)  { false }
      let(:expected_output) do
        <<~EXPECTED_OUTPUT
          Truemail #{validation_type} validation for #{email} failed (#{error})

          CONFIGURATION SETTINGS:
          whitelist validation: false
          not rfc mx lookup flow: false
          smtp fail fast: false
          smtp safe check: false
          email pattern: default gem value
          smtp error body pattern: default gem value
        EXPECTED_OUTPUT
      end

      describe 'whitelist validation' do
        let(:validation_type) { :whitelist }
        let(:expected_output) do
          <<~EXPECTED_OUTPUT
            Truemail blacklist validation for #{email} failed (domain list match: blacklisted email)

            CONFIGURATION SETTINGS:
            whitelist validation: false
            blacklisted domains: #{email[Truemail::RegexConstant::REGEX_EMAIL_PATTERN, 3]}
            not rfc mx lookup flow: false
            smtp fail fast: false
            smtp safe check: false
            email pattern: default gem value
            smtp error body pattern: default gem value
          EXPECTED_OUTPUT
        end

        include_examples 'formatted text output'
      end

      describe 'regex validation' do
        let(:validation_type) { :regex }
        let(:error) { 'regex: email does not match the regular expression' }

        include_examples 'formatted text output'
      end

      describe 'mx validation' do
        let(:validation_type) { :mx }
        let(:error) { 'mx: target host(s) not found' }

        include_examples 'formatted text output'
      end

      describe 'smtp validation' do
        let(:validation_type) { :smtp }
        let(:error) { 'smtp: smtp error' }

        context 'when smtp errors not includes ASCII-8BIT chars' do
          let(:expected_output) do
            <<~EXPECTED_OUTPUT
              Truemail #{validation_type} validation for #{email} failed (#{error})

              ATTEMPT #1:
              mail host: #{mx_servers.first}
              port opened: true
              connection: true
              errors:\u0020
              rcptto: user not found

              CONFIGURATION SETTINGS:
              whitelist validation: false
              not rfc mx lookup flow: false
              smtp fail fast: false
              smtp safe check: false
              email pattern: default gem value
              smtp error body pattern: default gem value
            EXPECTED_OUTPUT
          end

          include_examples 'formatted text output'
        end

        context 'when smtp errors includes ASCII-8BIT chars' do
          let(:error_context_with_ascii_8bit) { "\xD3\xE4\xB2\xBB\xD4" }
          let(:validator_instance) do
            create_validator(
              validation_type,
              email,
              mx_servers,
              success: success_status,
              rcptto_error: error_context_with_ascii_8bit
            )
          end
          let(:expected_output) do
            <<~EXPECTED_OUTPUT
              Truemail #{validation_type} validation for #{email} failed (#{error})

              ATTEMPT #1:
              mail host: #{mx_servers.first}
              port opened: true
              connection: true
              errors:\u0020
              rcptto: \uFFFD䲻\uFFFD

              CONFIGURATION SETTINGS:
              whitelist validation: false
              not rfc mx lookup flow: false
              smtp fail fast: false
              smtp safe check: false
              email pattern: default gem value
              smtp error body pattern: default gem value
            EXPECTED_OUTPUT
          end

          include_examples 'formatted text output'
        end
      end
    end
  end
end
