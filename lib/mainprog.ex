defmodule Mainprog do
   use GenServer
    
    def main(username,password) do
        register_user(username,password);
    end


    def register_user(username,password) do
        GenServer.start_link(__MODULE__, {username,password,{}}, name: String.to_atom(username)) 
        GenServer.start_link(__MODULE__, {"keyur","keyur",{}}, name: String.to_atom("keyur")) 
        follow_someone("karan","keyur")
        follow_someone("keyur","karan")
        GenServer.call(String.to_atom("karan"), {:print_state, {}})
        GenServer.call(String.to_atom("keyur"), {:print_state, {}})
        tweet("keyur", "Hi #karan")
        IO.puts "back"
        tweet("keyur", "Hi apurv")
        tweet("keyur", "Hi @abhi")
        tweet("karan", "I am bored")
        tweet("karan", "Elixir rocks")
        GenServer.call(String.to_atom("keyur"), {:print_state, {}})
        GenServer.call(String.to_atom("karan"), {:print_state, {}})
        IO.puts "-------------------"
        retweet("karan","keyur",0)
        IO.puts "-------------------"
        go_offline("karan")
        go_offline("keyur")
        IO.puts "-------------------"
        GenServer.call(String.to_atom("mainserver"), {:print_state, {}})

    end

    def init(args) do
        username = elem(args,0)
        passwd = elem(args,1)
        state = GenServer.call(String.to_atom("mainserver"),{:get_state, "mainserver"})       
        IO.inspect(state)  
        serv_resp = Map.get(state, String.to_atom(username))
        IO.inspect(serv_resp)
        if(serv_resp == nil) do
          state = %{"username" => username, "password" => passwd, "tweets" => [], "dashboard" => [], "followers"=>[],"following"=>[] }
        else
          state = serv_resp
        end
        {:ok,state}
    end 


    def go_online(tweeter) do
        
        GenServer.call(String.to_atom(tweeter), {:create_dashboard_list, {}})
    end

    
    def retweet(tweeter,someone,id) do
        IO.puts "retweeting"
        {tweeter,retweet_tweet} = GenServer.call(String.to_atom(tweeter), {:retweet, {someone,id}}) #add the retweeted tweet to tweeter's tweet list        
        tweet(tweeter,retweet_tweet) 
    end


    def follow_someone(tweeter,someone) do
        pid = Process.whereis(String.to_atom(someone))
        if(pid != nil && Process.alive?(pid) == true) do
            IO.puts "keyur is alive"
            GenServer.call(String.to_atom(someone), {:follow_someone_alive, {tweeter}}) #add tweeter(user) to the followers list of person he follows
            GenServer.call(String.to_atom(tweeter), {:follow_someone, {someone}}) #add the person whom user follows to users following list
        else
            GenServer.call(String.to_atom("mainserver"), {:follow_someone_dead, {tweeter}}) #add tweeter(user) to the followers list of person he follows
            GenServer.call(String.to_atom(tweeter), {:follow_someone, {someone}}) #add the person whom user follows to users following list
    end
        #GenServer.call(String.to_atom(someone), {:tweet, {tweet}})
    end


    def tweet(tweeter,tweet) do
        IO.puts "send tweet"
        {id,timestamp} = GenServer.call(String.to_atom(tweeter), {:tweet, {tweet}})
        parse_tweet(tweeter,tweet,id,timestamp)
    end 

    def go_offline(username) do 
        #state = GenServer.call(String.to_atom("mainserver"),{:get_state,"mainserver"})
        IO.puts username <> " going offline"
        user_state =  GenServer.call(String.to_atom(username),{:get_state,"user"})
        IO.inspect user_state
        GenServer.call(String.to_atom("mainserver"), {:go_offline, {username,user_state}})
    end

    def parse_tweet(tweeter,tweet,id,timestamp) do

        state = GenServer.call(String.to_atom("mainserver"),{:get_state, "mainserver"})  
        split_tweet = String.split(tweet);
        
        Enum.each(split_tweet, fn(n) -> 
            word = n
            if(String.first(word)=="#") do
                IO.puts "parsing"
                hashtag_map = Map.get(state,"hashtags")
                IO.inspect hashtag_map
                if(Map.get(hashtag_map,word) == nil) do
                    GenServer.call(String.to_atom("mainserver"), {:add_new_hashtag, {word,tweet,tweeter,id,timestamp}})
                else
                    GenServer.call(String.to_atom("mainserver"), {:add_hashtag, {word,tweet,tweeter,id,timestamp}})
                end
            end

            if(String.first(word)=="@") do
                mention_map = Map.get(state,"mentions")
                #IO.puts "mention"
                if(Map.get(mention_map,word)==nil) do
                  #mention_map = Map.put(mention_map,word,[tweet])
                  GenServer.call(String.to_atom("mainserver"), {:add_new_mention, {word,tweet,tweeter,id,timestamp}})
                else 
                  GenServer.call(String.to_atom("mainserver"), {:add_mention, {word,tweet,tweeter,id,timestamp}})
                end
            end
        end)    
    end


# call backs
  
  
  def handle_call({:get_state ,new_message},_from,state) do  
    {:reply,state,state}
  end

  def handle_call({:print_state ,new_message},_from,state) do 
    IO.inspect state 
    {:reply,state,state}
  end


  def handle_call({:create_dashboard_list,new_message},_from,state) do  
    tweeter_following_list = Map.get(state,"following")
    tweeter_dashboard_list = Map.get(state,"dashboard")
    server_state = GenServer.call(String.to_atom("mainserver"),{:get_state, "mainserver"}) 
    menion_map = Map.get(server_state,"mentions")
    tweeter_dashboard_list = tweeter_dashboard_list + Map.get(state,"tweets")
    Enum.each(tweeter_following_list, fn(n) -> 
            following_state = GenServer.call(String.to_atom(n),{:get_state, "get following peoples tweets"})  
            tweeter_dashboard_list = tweeter_dashboard_list + Map.get(following_state,"tweets")
    end)
    tweeter_dashboard_list = tweeter_dashboard_list +  Map.get(menion_map,"@"<>Map.get(state,"username"))
    {:reply,state,state}
  end


  def handle_call({:retweet ,new_message},_from,state) do  
    
    someone = elem(new_message,0)
    tweet_id = elem(new_message,1)
    IO.puts "still retweeting"
    someone_state = GenServer.call(String.to_atom(someone),{:get_state, "someone"})
    someone_tweet_list = Map.get(someone_state,"tweets")
    {id,timestamp,_,retweet_tweet} = Enum.at(someone_tweet_list,tweet_id)
    tweeter = Map.get(state,"username")
    
    {:reply,{tweeter,retweet_tweet},state}
  end

  def handle_call({:follow_someone ,new_message},_from,state) do
    someone = elem(new_message,0)
    following_list = Map.get(state,"following")
    following_list = following_list ++ [someone]
    state = Map.put(state, "following", following_list)
    {:reply,state,state}
  end

   def handle_call({:follow_someone_alive ,new_message},_from,state) do  
    follower = elem(new_message,0)
    follower_list = Map.get(state,"followers")
    follower_list = follower_list ++ [follower]
    state = Map.put(state, "followers", follower_list)
    {:reply,state,state}
   end

   
   def handle_call({:follow_someone_dead ,new_message},_from,state) do  
     follower = elem(new_message,0)
     all_users_map = Map.get(state,"users")
     cur_someone_data = Map.get(all_users_map,follower)
     cur_someone_follower_list = Map.get(cur_someone_data,"followers")
     cur_someone_follower_list = cur_someone_follower_list ++ [follower]
     cur_someone_data = Map.put(cur_someone_data,"followers",cur_someone_follower_list)
     all_users_map = Map.put(all_users_map,follower,cur_someone_data)
     state = Map.put(state,"users",all_users_map)
     {:reply,state,state}
  end


  def handle_call({:tweet, new_message},_from,state) do
    IO.puts Map.get(state,"username") <> "sending tweet"
    tweet = elem(new_message,0)
    tweeter = Map.get(state,"username")
    tweets_list = Map.get(state,"tweets")
    follower_list = Map.get(state,"followers") 
    IO.puts "still sending tweet"
    
    if List.last(tweets_list) == nil do
        last_tweet_id = -1
    else
        {last_tweet_id,_,_,_} = List.last(tweets_list)    
    end
    IO.inspect last_tweet_id
    timestamp = :os.system_time(:millisecond)

    tweets_list = tweets_list ++ [{last_tweet_id+1,timestamp,tweeter,tweet}]
    IO.inspect tweets_list
   
    state = Map.put(state,"tweets",tweets_list)
    Enum.each(follower_list, fn(n) ->
        pid = Process.whereis(String.to_atom(n))
        if(pid != nil && Process.alive?(pid) == true) do
            GenServer.call(String.to_atom(n), {:tweet_someone_alive, {last_tweet_id+1,timestamp,tweeter,tweet}})
        end
    end)
    IO.puts "tweet sent"
    {:reply,{last_tweet_id+1,timestamp},state}
  end

  def handle_call({:tweet_someone_alive, new_message},_from,state) do
        IO.puts "tweet someone alive"
       follower_dashboard_list = Map.get(state,"dashboard") 
       tweet =  elem(new_message,3)
       tweeter = elem(new_message,2)
       id = elem(new_message,0)
       timestamp = elem(new_message,1)
       follower_dashboard_list = follower_dashboard_list ++ [{id,timestamp,tweeter,tweet}]
       state = Map.put(state,"dashboard",follower_dashboard_list)
       {:reply,state,state}
  end



  

 
   
end 