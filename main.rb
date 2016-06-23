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
  firstname VARCHAR(20),\
  lastname VARCHAR(20),\
  gender VARCHAR(10),\
  sex_orient VARCHAR(20),\
  bio VARCHAR(250),\
  password VARCHAR(60),\
  token VARCHAR(60),\
  token_time DATETIME)")

client.query("CREATE TABLE IF NOT EXISTS user_coords (id INT KEY, latitude FLOAT(13,8), longitude FLOAT(13,8))")

helpers do

  def login?
    if session[:user].nil?
      return false
    else
      return true
    end
  end

  def validator(params = {})
    params.each do |k, check|
      if check.nil? || check == ''
        return false
      end
    end
    return true
  end

  def username
    return session[:user]
  end

end

get "/" do
  results = client.query("SELECT * FROM users")
  session["ip"] = request.ip
  haml :index
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

get "/signup" do
  haml :signup
end

post "/signup" do
  if validator(params)
    statement = client.prepare("SELECT id from users where email = ? OR login = ?")
    res = statement.execute(params['email'], params['login'])
    if res.count > 0
     session[:warning] = "This login or email is already associated with an existing account."
     redirect "/signup"
    else
      password = Password.create(params["password"]) #Genere le hash
      state = client.prepare("INSERT INTO users (login, password, email, firstname, lastname) VALUES (?, ?, ?, ?, ?)") #On cree un nouvel user
      state.execute(params['login'], password, params['email'], params['firstname'], params['lastname'])
      session[:success] = "Account successfully created."
      redirect "/"
    end
  else
    session[:warning] = "One or more required fields are missing."
    redirect "/signup"
  end
end

post "/login" do
  if session && validator(params)
    state = client.prepare("SELECT * from users WHERE login = ?")
    res = state.execute(params['username'])
    res.each {|row| session[:user] = row}
    if res.count == 1 && Password.new(session[:user]["password"]) == params['password']
      session[:success] = "You are now logged in as #{session[:user]["login"]}"
      redirect "/"
    end
  else
    session[:warning] = "one or more field are empty."
    redirect "/"
  end
end

get '/play/:lat/:lon' do
  if request.xhr? && login?
    state = client.prepare("INSERT INTO user_coords (id, latitude, longitude) VALUES(?, ?, ?) ON DUPLICATE KEY UPDATE latitude=? , longitude=?")
    state.execute(session[:user]['id'],params['lat'],params['lon'],params['lat'],params['lon'])
    "test"
  end
end

get "/logout" do
  session[:user] = nil
  session[:success] = "You are logged out, see you soon."
  redirect "/"
end



