# Omniauth Traity [![Build Status](https://travis-ci.org/traity/omniauth-traity.svg?branch=master)](https://travis-ci.org/traity/omniauth-traity)

Traity Oauth2 Strategy for OmniAuth. Supports the OAuth 2.0 server side and client side flows. You can read Traity for Startups [documentation](https://startups.traity.com/documentation/verification) for more details about implementation.

## Installation

Add to your `Gemfile`:

```ruby
gem 'omniauth-traity'
```

And then execute `bundle install`.

## Usage

`OmniAuth::Strategies::Traity` is a Rack middleware and plays under the rules of OmniAuth so you can read the detailed documentation about it: https://github.com/intridea/omniauth.

The configuration in Ruby on Rails can be placed at `config/initializers/omniauth.rb` and looks like:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :traity, ENV['TRAITY_APP_KEY'], ENV['TRAITY_APP_SECRET']
end
```

For a Sinatra app it's almost the same, you just have to tell the middleware to establish a cookie secret and to use the builder. For example, in `config.ru`:

```ruby
require 'bundler/setup'
require 'omniauth-traity'
require './app.rb'

use Rack::Session::Cookie, :secret => 'abc123'

use OmniAuth::Builder do
  provider :traity, ENV['TRAITY_APP_KEY'], ENV['TRAITY_APP_SECRET']
end

run Sinatra::Application
```

Remember you need to get a key and secret going to http://startups.traity.com and registering as a developer.

## Configuration Options

Option name | Default | Explanation
--- | --- | ---
`display` | `page` | The display context to show the authentication page. Options are: `page` and `popup`. Read the Traity docs for more details.
`locale` | `nil` | Specify locale which should be used when getting the user's info. Value should be a valid locale string.
`callback_url` / `callback_path` | | Specify a custom callback URL used during the server-side flow. Note this must be allowed by your app configuration on Traity.

For example, to request info in *spanish* and using a popup window, you should configure with something like:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :traity, ENV['TRAITY_APP_KEY'], ENV['TRAITY_APP_SECRET'],
           :locale => 'es_ES', :display => 'popup'
end
```

In the near future we will be adding more configuration options. Also, remember that you can override configuration parameters by adding them to the querystring during the request. For example, if you link the user to `/auth/traity?display=screen` it doesn't matter if the configuration is set to display as a popup, the parameter will be overridden.

## Authorization hash

Here is an example of the hash available in `request.env['omniauth.auth']`:

```ruby
{
  :provider => 'traity',
  :uid => 'aGsaXs133sd2',
  :info => {
    :name => "Walter White",
    :email => "heisenberg@bluemeth.co",
    :bio => "Former proffesor turn into meth cook",
    :picture => 'https://traity-staging.s3.amazonaws.com/pictures/de060a/profile_8.JPG',
    :cover_picture => 'https://traity-staging.s3.amazonaws.com/pictures/de060a/profile_8.JPG',
    :gender => "male",
    :location => "Albuquerque, NM",
    :reputation => 4.3,
    :email_verified => true,
  },
  :credentials => {
    :token => 'ABCDEF...', # OAuth 2.0 access_token, which you may wish to store
    :expires_at => 1321747205, # when the access token expires (it always will)
    :expires => true, # this will always be true
    :refresh_token => 'ABCD...'
  }
}
```

## Clien-side Flow with Traity Javascript SDK

You can use the Traity Javascript SDK with `Traity.login`, and just hit the callback endpoint once the user has authenticated in the success callback. You can see an example at Traity Documentation.

### How it works

Similar to Facebook's. The client-side flow is supported by parsing the authorization code from the signed request which is placed in a cookie by the Traity SDK. When you call `/auth/traity/callback` in the success, omniauth-traity will parse the cookie, extract the authorization code and finish the flow for you to get a long-lived access token.

Token expiration will always depend on the version, app and token that you are using.

## License

Copyright (c) 2012 by Traity

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
