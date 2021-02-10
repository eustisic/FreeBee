require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"
require "json"

require_relative "puzzle_maker.rb"

configure do
	enable :sessions
	
	set :session_store, Rack::Session::Pool
	use Rack::Session::Pool, :expire_after => 2592000
	use Rack::Protection::RemoteToken
	use Rack::Protection::SessionHijacking
end

before do 
	session[:puzzle] ||= FreeBee.new_puzzle

	@word = session[:word] ||= ""
	@total = session[:total] ||= 0
	@word_list = session[:word_list] ||= Array.new
	@words = session[:puzzle][:words]
	@key = session[:puzzle][:key][0]
	@letters = session[:puzzle][:letters]
	@winning_score = session[:puzzle][:score]
end

def resp_hash
	resp = {
		'word' => session[:word],
		'total' => session[:total],
		'word_list' => session[:word_list],
		'key' => session[:puzzle][:key][0],
		'letters' => session[:puzzle][:letters],
		'winning_score' => session[:puzzle][:score],
		'message' => session[:message],
		'score' => session[:score]
	}
end

def pangram?(word)
	word.chars.uniq.length == 7
end

def score(word) 
	case word.length
	when 4 then [1, "Great!"]
	when 5 then [5, "Nice!"]
	when 6 then [10, "Fantastic!"]
	when 7 then [15, "Prodigious!"]
	else
		[20, "Lexicomane!"]
	end
end

def flash(message)
	session[:message] = message
end

def generate_message
	word_score = score(@word)
	
	if @word_list.include?(@word)
		flash("Already found")
	elsif !@word.chars.include?(@key)
		flash("Does not include central letter")
	elsif pangram?(@word) && @words.include?(@word)
		@word_list << @word
		session[:score] = word_score[0]
		flash("Pangram!")
	elsif @words.include?(@word)
		@word_list << @word
		session[:score] = word_score[0]
		flash word_score[1]
	else
		flash("Not a word")
	end
end

def game_reset
	session[:puzzle] = FreeBee.new_puzzle
	session.delete(:word_list)
	session.delete(:total)
	session.delete(:word)
end

# Routes
get "/" do
  erb :home
end

get "/api" do
	JSON.generate(resp_hash)
end

post "/shuffle" do
	@letters.shuffle!
	JSON.generate(resp_hash)
end

post "/add/:letter" do
	session[:word] << params[:letter]
end

post "/delete" do
	@word.chop!
	session[:word]
end

post "/enter" do
	generate_message
	session[:total] += session[:score].to_i
	resp = JSON.generate(resp_hash)
	session.delete(:word)
	session.delete(:score)
	resp
end

post "/reset" do
	game_reset
	JSON.generate(resp_hash);
end
