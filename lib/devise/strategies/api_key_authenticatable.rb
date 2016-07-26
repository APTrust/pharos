# This blog post was helpful:
# http://kyan.com/blog/2013/10/11/devise-authentication-strategies

module Devise
  module Strategies
    class ApiKeyAuthenticatable < Base

      include ApiAuth

      def valid?
        api_request?
      end

      # This MUST return false, or API sessions will time out.
      # We don't want API sessions to time out. As long as we
      # get valid credentials in the header, let the API user in.
      def store?
        false
      end

      # Authenticate API user via email and API key.
      def authenticate!
        api_user = request.headers["X-Pharos-API-User"]
        api_key = request.headers["X-Pharos-API-Key"]
        user = User.find_by_email(api_user)
        unless user
          fail!
          return
        end
        authenticated = api_key.nil? == false && user.valid_api_key?(api_key)
        authenticated ? success!(user) : fail!
      end

    end
  end
end
