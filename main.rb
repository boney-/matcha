require 'sinatra'
require 'sinatra/reloader'
require 'data_mapper'
require 'dm-mysql-adapter'
require 'dm-migrations'
require 'bcrypt'
require 'rubygems'
require 'haml'
require 'rack-flash'
include BCrypt

register Sinatra::Reloader


DataMapper.setup(:default, 'mysql://root:root42@localhost/matcha')

class User
  include DataMapper::Resource

  property :id,         Serial
  property :email,      String
  property :gender,     String
  property :sex_orient, String
  property :bio,        Text          
  property :pass,       BCryptHash
  property :created_at, DateTime
end

DataMapper.finalize
#
DataMapper.auto_upgrade!

enable :sessions
use Rack::Flash

helpers do

  def login?
    if session[:username].nil?
      return false
    else
      return true
    end
  end

  def username
    return session[:username]
  end

end

get "/" do
  haml :index
end

get "/signup" do
  haml :signup
end


post "/signup" do
  #ideally this would be saved into a database
  count = User.count(:conditions => ['email =?', params["email"]])
  if count > 0
    flash[:warning] = "This email is already associated with an existing account."
    redirect "/"
  else
    password = Password.create(params["password"]) #Genere le hash
    user = User.new(:email => params["email"], :gender => "male", :pass => Password.create(params["password"])) #On cree un nouvel user
    if user.save #Handler pour erreurs du save sur la db
      flash[:sucess] = "User sucefully created"
      redirect "/"
    else
      user.errors.each do |e|
        return e
      end
    end
  end
end

post "/login" do
  if session
    user = userTable[params[:username]]
    if user[:passwordhash] == BCrypt::Engine.hash_secret(params[:password], user[:salt])
      session[:username] = params[:username]
      redirect "/"
    end
  end
  haml :error
end

get "/logout" do
  session[:username] = nil
  redirect "/"
end
