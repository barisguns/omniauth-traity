require 'omniauth'
require 'pp'

module OmniAuth
  module Strategies
    class Traity < OmniAuth::Strategies::OAuth2
      option :fields, [:name, :email]
      option :uid_field, :id

      option :client_options, {
        site:          'https://api.traity.com/',
        authorize_url: 'https://traity.com/oauth/dialog',
        token_url:     'oauth/token'
      }

      uid { raw_info['id'] }

      info do
        prune!({
          'name' => raw_info['name'],
          'email' => raw_info['email'],
          'bio' => raw_info['bio'],
          'picture' => raw_info['picture'],
          'cover_picture' => raw_info['cover_picture'],
          'gender' => raw_info['gender'],
          'location' => raw_info['location'],
          'reputation' => raw_info['reputation'],
          'email_verified' => (raw_info['verified'] || {}).has_key?('email')
        })
      end

      def raw_info
        @raw_info ||= access_token.get('1.0/me').parsed || {}
      end

      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end
    end
  end
end