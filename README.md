# 1. Dependencies

```
# JWT GEMS
gem 'dotenv-rails', groups: [:development, :test]
gem 'devise'
gem 'devise-jwt'
```

Then, run

```
$ bundle install 

// or just

$ bundle
```

# 2. Inicializating Devise

```
$ rails generate devise:install
```

```
$ rails generate devise User
```

# 3. Adapting user model 

user.rb (model)
```
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :registerable,
         :database_authenticatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self
end
```

migration
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

devise.rb (initializer)
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

```
$ rails secret
```

.env file
```
DEVISE_JWT_SECRET_KEY
```

# 5. Login/logout endpoints
```
$ rails generate controller auth/sessions
```

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
```
$ rails generate controller auth/registrations
```

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