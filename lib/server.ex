
defmodule Server do
    use GenServer
    
    def main() do   
        IO.puts "Server reached"
        server_name = "server@" <> get_ip_addr()
        Node.start(String.to_atom(server_name))
        Node.set_cookie :"choco"
        GenServer.start_link(Server, {}, name: String.to_atom("mainserver"))   
        IO.puts "Server created"
        IO.gets ""
    end


    def get_ip_addr do 
        {:ok,lst} = :inet.getif()
        z = elem(List.last(lst),0) 
        if elem(z,0)==127 do
        x = elem(List.first(lst),0)
        addr =  to_string(elem(x,0)) <> "." <>  to_string(elem(x,1)) <> "." <>  to_string(elem(x,2)) <> "." <>  to_string(elem(x,3))
        else
        x = elem(List.last(lst),0)
        addr =  to_string(elem(x,0)) <> "." <>  to_string(elem(x,1)) <> "." <>  to_string(elem(x,2)) <> "." <>  to_string(elem(x,3))
        end
        addr  
    end


    def init(state) do
        state = %{"users" => %{}, "hashtags" => %{}, "mentions" => %{}}
        {:ok,state}
    end 

    def handle_call({:get_state ,new_message},_from,state) do  
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




    def handle_call({:register_user ,new_message},_from,state) do 
         username = elem(new_message,0)
         password = elem(new_message,1)
         all_users_state =  Map.get(state,"users")
         ins_state = %{"username" => username, "password" => password, "tweets" => [], "dashboard" => [], "followers"=>[],"following"=>[] }
         all_users_state = Map.put(all_users_state,username,ins_state)
         state = Map.put(state, "users", all_users_state)
         {:reply,state,state}
    end

    def handle_call({:print_state ,new_message},_from,state) do 
        IO.inspect state 
        {:reply,state,state}
    end

    def handle_call({:is_online ,new_message},_from,state) do 
        user = elem(new_message, 0)
        #IO.puts to_string(user) <> " is back online" 
        {:reply,state,state}
    end

    def handle_call({:is_offline ,new_message},_from,state) do 
        user = elem(new_message, 0)
        IO.puts to_string(user) <> " went offline" 
        {:reply,state,state}
    end

    def handle_call({:go_offline ,new_message},_from,state) do  
        #IO.puts "still going offline"
        username = elem(new_message,0)
        #IO.puts username
        user_state = elem(new_message,1)
        all_users_state = Map.get(state,"users")
        all_users_state = Map.put(all_users_state,username,user_state)
        state = Map.put(state,"users",all_users_state)
        {:reply,state,state}
    end

    def handle_call({:add_new_hashtag, msg},_from,state) do
       hashtag = elem(msg,0)
       tweet =  elem(msg,1)
       tweeter = elem(msg,2)
       id = elem(msg,3)
       timestamp = elem(msg,4)
       hashtag_map = Map.get(state,"hashtags")
       hashtag_map =  Map.put(hashtag_map,hashtag,[{id,timestamp,tweeter,tweet}])
       state = Map.put(state,"hashtags",hashtag_map)
       {:reply,state,state}
  end

  def handle_call({:add_hashtag, msg},_from,state) do
       hashtag = elem(msg,0)
       tweet =  elem(msg,1)
       tweeter = elem(msg,2)
       id = elem(msg,3)
       timestamp = elem(msg,4)
       hashtag_map = Map.get(state,"hashtags")
       hashtag_list = Map.get(hashtag_map,hashtag)
       hashtag_list = hashtag_list ++ [{id,timestamp,tweeter,tweet}]
       hashtag_map = Map.put(hashtag_map,hashtag,hashtag_list)
       state = Map.put(state,"hashtags",hashtag_map)
       {:reply,state,state}
  end

  def handle_call({:add_mention, msg},_from,state) do
       mention = elem(msg,0)
       tweet =  elem(msg,1)
       tweeter = elem(msg,2)
       id = elem(msg,3)
       timestamp = elem(msg,4)
       mention_map = Map.get(state,"mentions")
       mention_list = Map.get(mention_map,mention)
       mention_list = mention_list ++ [{id,timestamp,tweeter,tweet}]
       mention_map = Map.put(mention_map,mention,mention_list)
       state = Map.put(state,"mentions",mention_map)
       {:reply,state,state}
  end

  def handle_call({:add_new_mention, msg},_from,state) do
       #IO.puts "new mention"
       mention = elem(msg,0)
       allusers_map = Map.get(state,"users")
       #IO.inspect allusers_map
       mentionwithoutatrate = String.replace(mention, "@", "")
       #IO.inspect mentionwithoutatrate
       #IO.inspect Map.get(allusers_map,mentionwithoutatrate)
       if(Map.get(allusers_map,mentionwithoutatrate) != nil) do
            #IO.puts "user present"
            tweet =  elem(msg,1)
            tweeter = elem(msg,2)
            id = elem(msg,3)
            timestamp = elem(msg,4)
            mention_map = Map.get(state,"mentions")
            mention_map =  Map.put(mention_map,mention,[{id,timestamp,tweeter,tweet}])
            state = Map.put(state,"mentions",mention_map)
        end
       {:reply,state,state}
  end

end
