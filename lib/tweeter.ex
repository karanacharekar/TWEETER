defmodule Tweeter do
  
    
    
    
    def init(args) do
        username = elem(args,0)
        passwd = elem(args,0)
        state = GenServer.call(String.to_atom(mainserver),{:get_state, "mainserver"})         
        serv_resp = Map.fetch(state, String.to_atom(username))
        if(elem(serv_resp,0)== String.to_atom("ok")){
          state = elem(serv_resp,1)
        }
        else{
          state = {"username" => username, "password" => passwd, "tweets" => [], "dashboard" => [], "followers"=>[],"following"=>[] }
        }
    end 


    def go_online(tweeter) do
        GenServer.call(String.to_atom(tweeter), {:create_dashboard_list, {}})
    end

    
    def retweet(tweeter,someone,id) do
        GenServer.call(String.to_atom(tweeter), {:retweet, {someone,id}}) #add the retweeted tweet to tweeter's tweet list
    end

    
    def follow_someone(tweeter,someone) do
        pid = Process.whereis(String.to_atom(someone))
        if(pid != nil && Process.alive?(pid) == true) do
            GenServer.call(String.to_atom(someone), {:follow_someone_alive, {tweeter}}) #add tweeter(user) to the followers list of person he follows
            GenServer.call(String.to_atom(tweeter), {:follow_someone, {someone}}) #add the person whom user follows to users following list
        else
            GenServer.call(String.to_atom("mainserver"), {:follow_someone_dead, {tweeter}}) #add tweeter(user) to the followers list of person he follows
            GenServer.call(String.to_atom(tweeter), {:follow_someone, {someone}}) #add the person whom user follows to users following list
    end
        #GenServer.call(String.to_atom(someone), {:tweet, {tweet}})
    end


    def tweet(tweeter,tweet) do
        GenServer.call(String.to_atom(tweeter), {:tweet, {tweet}})
        parse_tweet(tweeter,tweet)
    end

    def go_offline(username) do 
        #state = GenServer.call(String.to_atom("mainserver"),{:get_state,"mainserver"})
        user_state =  GenServer.call(String.to_atom(username),{:get_state,"user"})
        GenServer.call(String.to_atom("mainserver"), {:go_offline, {username,user_state}})
    end

    def parse_tweet(tweeter,tweet) do
        state = GenServer.call(String.to_atom("mainserver"),{:get_state, "mainserver"})  
        split_tweet = String.split(tweet);
        Enum.each(split_tweet, fn(n) -> 
            word = n
            if(String.first(word)=="#"){
                hashtag_map = Map.get(state,"hashtag")
                if(Map.fetch(hashtag_map,word,"none") == "none"){
                    GenServer.call(String.to_atom("mainserver"), {:add_new_hashtag, {word,tweet,tweeter}})
                }
                else{
                    GenServer.call(String.to_atom("mainserver"), {:add_hashtag, {word,tweet,tweeter}})
                }
            }

            else if(String.first(word)=="@"){
                mention_map = Map.get(state,"mentions")
                if(Map.fetch(mention_map,word,"none")=="none"){
                  mention_map = Map.put(mention_map,word,[tweet])
                  GenServer.call(String.to_atom("mainserver"), {:add_new_mention, {word,tweet,tweeter}})
                }
                else{
                  GenServer.call(String.to_atom("mainserver"), {:add_mention, {word,tweet,tweeter}})
                }
            }
    end


# call backs
  
  
  def handle_call({:get_state ,new_message},_from,state) do  
    {:reply,state,state}
  end


  def handle_call({:create_dashboard_list,new_message},_from,state) do  
    tweeter_following_list = Map.get(state,"following")
    tweeter_dashboard_list = Map.get(state,"dashboard")
    Enum.each(tweeter_following_list, fn(n) -> 

    end)    
    {:reply,state,state}
  end


  def handle_call({:retweet ,new_message},_from,state) do  
    someone = elem(new_message,0)
    tweet_id = elem(new_message,1)
    someone_state = GenServer.call(String.to_atom(someone),{:get_state, "someone"})
    someone_tweet_list = Map.get(someone_state,"tweets")
    (retweet_tweet,id) = Enum.at(someone_tweet_list,tweet_id)
    tweeter = Map.get(state,"username")
    tweet(tweeter,retweet_tweet)  
    {:reply,state,state}
  end

  def handle_call({:follow_someone ,new_message},_from,state) do  
    someone = elem(new_message,0)
    following_list = Map.get(state,"following")
    following_list = following_list ++ [someone]
    {:reply,state,state}
  end

   def handle_call({:follow_someone_alive ,new_message},_from,state) do  
    follower = elem(new_message,0)
    follower_list = Map.get(state,"followers")
    follower_list = follower_list ++ [follower]
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
    tweet = elem(new_message,0)
    tweets_list = Map.get(state,"tweets")
    {last_tweet_id,_} = List.last(tweets_list)
    tweets_list = tweets_list ++ [{last_tweet_id+1,os.system_time(:millisecond),tweet}]
    state = Map.put(state,"tweets",tweets_list)
    {:reply,state,state}
  end


  def handle_call({:go_offline ,new_message},_from,state) do  
    isername = elem(new_message,0)
    user_state = elem(new_message,1)
    state = Map.put(state,username,user_state)
    {:reply,state,state}
  end

  def handle_call({:add_new_hashtag, msg},_from,state) do
       hashtag = elem(msg,0)
       tweet =  elem(msg,1)
       tweeter = elem(msg,2)
       hashtag_map = Map.get(state,"hashtags")
       hashtag_map =  Map.put(hashtag_map,hashtag,[{tweeter,tweet}])
       state = Map.put(state,"hashtags",hashtag_map)
  end

  def handle_call({:add_hashtag, msg},_from,state) do
       hashtag = elem(msg,0)
       tweet =  elem(msg,1)
       tweeter = elem(msg,2)
       hashtag_map = Map.get(state,"hashtags")
       hashtag_list = Map.get(hashtag_map,hashtag)
       hashtag_list = hashtag_list ++ [{tweeter,tweet}]
       hashtag_map = Map.put(hashtag_map,hashtag,hashtag_list)
       state = Map.put(state,"hashtags",hashtag_map)
  end

  def handle_call({:add_mention, msg},_from,state) do
       mention = elem(msg,0)
       tweet =  elem(msg,1)
       tweeter = elem(msg,2)
       mention_map = Map.get(state,"mentions")
       menion_list = Map.get(mention_map,hashtag)
       mention_list = mention_list ++ [{tweeter,tweet}]
       mention_map = Map.put(mention_map,mention,mention_list)
       state = Map.put(state,"mentions",hashtag_map)
  end

  def handle_call({:add_new_mention, msg},_from,state) do
       mention = elem(msg,0)
       tweet =  elem(msg,1)
       tweeter = elem(msg,2)
       mention_map = Map.get(state,"mentions")
       mention_map =  Map.put(mention_map,mention,[{tweeter,tweet}])
       state = Map.put(state,"mentions",hashtag_map)
  end

end
