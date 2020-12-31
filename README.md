# 1. Installing Dependencies

First, go to the `Gemfile` and paste the following content:
```
# JWT GEMS
gem 'dotenv-rails', groups: [:development, :test] # For enviroment variables management & isolation at .env file
gem 'devise' # User management
gem 'devise-jwt' # JWT (JSON Web Token) configuration for devise
```

Then, bundle command to install the added gems:
```
$ bundle install 

// or just

$ bundle
```

# 2. Inicializating Devise

Install the basics to use devise:
```
$ rails generate devise:install
```
Generate the User model with devise:
```
$ rails generate devise User
```

# 3. Adapting user model 

Now, we need to configure the User model to work with `devise-jwt`:
```
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :registerable,
         :database_authenticatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self
end
```
  
We are using the JTI revocation strategy (the Gem have others), now you MUST add the following content to a **new migration** to add the JTI columns to users table:
```
  def change
    add_column :users, :jti, :string, null: false
    add_index :users, :jti, unique: true
    # If you already have user records, you will need to initialize its `jti` column before setting it to not nullable. Your migration will look this way:
    # add_column :users, :jti, :string
    # User.all.each { |user| user.update_column(:jti, SecureRandom.uuid) }
    # change_column_null :users, :jti, false
    # add_index :users, :jti, unique: true
  end
```

# 4. Configuring devise

Go to the **devise initializer** and paste the following content to configure the token options:
```
# DEVISE JWT
config.jwt do |jwt|
 jwt.secret = ENV['DEVISE_JWT_SECRET_KEY']
 jwt.dispatch_requests = [
   ['POST', %r{^/login$}]
 ]
 jwt.revocation_requests = [
   ['DELETE', %r{^/logout$}]
 ]
 jwt.expiration_time = 1.day.to_i
end

config.navigational_formats = []
```

Generate a random secret key on terminal and copy that to paste at the .env file.
```
$ rails secret
```

* The `.env` file must be like this:
```
...
DEVISE_JWT_SECRET_KEY=your_secret_key
....
```

# 5. Login/logout endpoints
Now, we have to configure the login & logout endpoints with a controller to start or end a session.
```
$ rails generate controller auth/sessions
```

After created, paste the following content at the controller:
```
class Auth::SessionsController < Devise::SessionsController
    respond_to :json
    
    def respond_with(resource, _opts = {})
      render json: resource
    end
  
    def respond_to_on_destroy
      head :no_content
    end
end
```

# 5. Registration endpoint
Now, we have to configure the registration endpoint with a controller to create a new user.
```
$ rails generate controller auth/registrations
```

After created, paste the following content at the controller:
```
class Auth::RegistrationsController < Devise::RegistrationsController
    respond_to :json
  
    def create
      build_resource(sign_up_params)
  
      resource.save
  
      if resource.errors.empty?
        render json: resource
      else
        render json: resource.errors
      end
    end
end
```

# 6. Routes settings
```
Rails.application.routes.draw do
  
  devise_for :users,
  path: 'auth',
  path_names: {
  sign_in: 'login',
  sign_out: 'logout',
  registration: 'register'
  },
  controllers: {
  sessions: 'auth/sessions',
  registrations: 'auth/registrations'
  }  

  # ...  
end
```

# 7. Protecting routes

Example:
```
class ProtectedController < ApplicationController
before_action :authenticate_user!

    def index
        render json: current_user
    end
end
```