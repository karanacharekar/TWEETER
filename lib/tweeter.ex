defmodule Tweeter do
  
    def init(args) do
        username = elem(args,0)
        passwd = elem(args,0)
        state = GenServer.call(String.to_atom(mainserver),{:get_state, "mainserver"})         
        serv_resp = Map.fetch(state, String.to_atom(username)
        if(elem(serv_resp,0)== String.to_atom("ok")){
          state = elem(serv_resp,1)
        }
        else{
          state = {"username" => username, "password" => passwd, "tweets" => [], "follwers"=>[],"follwing"=>[] }
        }
    end 


    def go_online() do

    end

    def tweet(tweeter,tweet) do


        parse_tweet
    end

    def go_offline(username) do 
        #state = GenServer.call(String.to_atom("mainserver"),{:get_state,"mainserver"})
        user_state =  GenServer.call(String.to_atom(username),{:get_state,"user"})
        GenServer.call(String.to_atom("mainserver"), {:go_offline, {user_state}})
    end

    def parse_tweet(tweeter,tweet) do
        state = GenServer.call(String.to_atom("mainserver"),{:get_state, "mainserver"})  
        split_tweet = String.split(tweet);
        Enum.each(split_tweet, fn(n) -> 
            word = n
            if(String.first(word)=="#"){
                hashtag_map = Map.get(state,"hashtag")
                if(Map.fetch(hashtag_map,word,"none") == "none"){
                    GenServer.call(String.to_atom("mainserver"), {:add_new_hashtag, {word,tweet}})
                }
                else{
                    GenServer.call(String.to_atom("mainserver"), {:add_hashtag, {word,tweet}})
                }
            }

            else if(String.first(word)=="@"){
                mention_map = Map.get(state,"mentions")
                if(Map.fetch(mention_map,word,"none")=="none"){
                  mention_map = Map.put(mention_map,word,[tweet])
                  GenServer.call(String.to_atom("mainserver"), {:add_new_mention, {word,tweet}
                }
                else{
                  GenServer.call(String.to_atom("mainserver"), {:add_mention, {word,tweet}
                }
            }

    end


# call backs
  
  

  def handle_call({:get_state ,new_message},_from,state) do  
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
       hashtag_map = Map.get(state,"hashtag")
       hashtag_map =  Map.put(hashtag_map,hashtag,[tweet])
       state = Map.put(state,"hashtag",hashtag_map)
  end

  def handle_call({:add_hashtag, msg},_from,state) do
       hashtag = elem(msg,0)
       tweet =  elem(msg,1)
       hashtag_map = Map.get(state,"hashtag")
       hashtag_list = Map.get(hashtag_map,hashtag)
       hashtag_list = hashtag_list ++ [tweet]
       hashtag_map = Map.put(hashtag_map,hashtag,hashtag_list)
       state = Map.put(state,"hashtag",hashtag_map)
  end

  def handle_call({:add_mention, msg},_from,state) do
  end

end
