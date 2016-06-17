require 'sinatra'
require 'sinatra/reloader'
require 'data_mapper'
require 'dm-mysql-adapter'
require 'dm-migrations'
require 'bcrypt'
require 'rubygems'
require 'haml'
require 'securerandom'
require 'mysql2'
include BCrypt

register Sinatra::Reloader


enable :sessions

client = Mysql2::Client.new(:host => "localhost", :username => "root", :password => "root42", :database => "matcha")
client.query("CREATE TABLE IF NOT EXISTS users (\
  id INT KEY AUTO_INCREMENT,\
  login VARCHAR(32),\
  email VARCHAR(20),\
  name VARCHAR(20),\
  surname VARCHAR(20),\
  gender VARCHAR(10),\
  sex_orient VARCHAR(20),\
  bio VARCHAR(250),\
  password VARCHAR(60))")

# class User
#   def initialize(id, login, email, name, surname, gender, sex_orient, bio)
#     @id = id
#     @login = login
#     @email = email
#     @name = name
#     @surname = surname
#     @gender = gender
#     @sex_orient = sex_orient
#     @bio = bio
#   end
# end

helpers do

  def login?
    if session[:user].nil?
      return false
    else
      return true
    end
  end

  def username
    return session[:user]
  end

end

get "/" do
  results = client.query("SELECT * FROM users")
  haml :index
end

get "/signup" do
  haml :signup
end

#Reset du password ###----

get "/reset" do
  haml :resetpass
end

post "/reset" do
  if params[:email]
    state = client.prepare("SELECT id from users WHERE email = ?")
    res = state.execute(params[:email]) # <- check si l'email existe dans la db.
    if res.count > 0
      state = client.prepare("UPDATE users SET token = ?, token_time = NOW() + INTERVAL 1 DAY WHERE email = ?")
      rand = SecureRandom.hex(60) # <- create token
      state.execute(rand, params[:email])
      # -------- SENT EMAIL MESSAGE : blablabla: url : /ip:4567/forgot/#{token}/
      "We sent the instructions to you."
    else
      "it seems that your email is not registered in our database."
    end
  end
end

get "/forgot/:token/" do
  if params["token"].length == 60
    session[:token] = params["token"]
    haml :newpass
  end
end

post "/forgot" do
  if params[:token].length == 60
    state = client.prepare("SELECT token_time from users WHERE token = ?")
    res = state.execute(params[:token])
    if res.count > 0
      state = client.prepare("UPDATE users SET password = ?, token = null, token_time = null WHERE token = ? AND `token_time` > now()")
      state.execute(params[:password], params[:token])
      session[:success] = "Password reset successfully"
      redirect "/"
    end
  end
  "An error occured, make sure your token is good or contact a administrator."
end

#------------------------

post "/signup" do
  #ideally this would be saved into a database
  if params['login'] && params['password']
    statement = client.prepare("SELECT id from users where email = ? OR login = ?")
    res = statement.execute(params['email'], params['login'])
    if res.count > 0
     session[:warning] = "This login or email is already associated with an existing account."
     redirect "/signup"
    else
      password = Password.create(params["password"]) #Genere le hash
      state = client.prepare("INSERT INTO users (login, password) VALUES (?, ?)") #On cree un nouvel user
      state.execute(params['login'], password)
      session[:success] = "Account successfully created."
      redirect "/signup"
    end
  else
    session[:warning] = "One or more required fields are missing."
    redirect "/signup"
  end
end

post "/login" do
  if session && params['username'] && params['password']
    state = client.prepare("SELECT * from users WHERE login = ?")
    res = state.execute(params['username'])
    res.each {|row| session[:user] = row}
    if res.count == 1 && Password.new(session[:user]["password"]) == params['password']
      session[:success] = "You are now logged in as #{session[:user]["login"]}"
      redirect "/"
    end
  end
end

get "/logout" do
  session[:user] = nil
  session[:success] = "You are logged out, see you soon."
  redirect "/"
end
