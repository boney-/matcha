require 'sinatra'
require 'sinatra/reloader'
require 'data_mapper'
require 'dm-mysql-adapter'
require 'dm-migrations'
require 'bcrypt'
require 'rubygems'
require 'haml'
include BCrypt

register Sinatra::Reloader

DataMapper.setup(:default, 'mysql://root:root42@localhost/matcha')

class User
  include DataMapper::Resource

  property :id,         Serial
  property :login,      String
  property :pass,       String
  property :created_at, DateTime
end

DataMapper.finalize
#
# DataMapper.auto_migrate!

enable :sessions

userTable = {}

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
  # haml :index
  pass = Password.new("$2a$10$Voyzr67pj/nbxwTQW1xjE.ZmfQu19X/Xr.V3soTfwJSY5Ld59tJxC")
  if pass == "coco"
    "allo"
  else
    "no"
  end
end

get "/signup" do
  haml :signup
end

post "/signup" do
  password = BCrypt::Password.create("test")
  #ideally this would be saved into a database, hash used just for sample
  User.create(:login => params[:username], :pass => password)
  "ok"
end

post "/login" do
  if userTable.has_key?(params[:username])
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
