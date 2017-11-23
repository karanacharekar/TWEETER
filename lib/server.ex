defmodule Server do
    use GenServer
    
    def main() do   
        IO.puts "Server reached"
        GenServer.start_link(Server, {}, name: String.to_atom("mainserver"))   
        IO.puts "Server created"
        IO.gets ""
    end

    def init(state) do
        state = %{"users" => %{}, "hashtags" => %{}, "mentions" => %{}}
        {:ok,state}
    end 

    def handle_call({:get_state ,new_message},_from,state) do  
         {:reply,state,state}
    end

    def handle_call({:print_state ,new_message},_from,state) do 
        IO.inspect state 
        {:reply,state,state}
    end

    def handle_call({:go_offline ,new_message},_from,state) do  
        IO.puts "still going offline"
        username = elem(new_message,0)
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
       IO.puts "new mention"
       mention = elem(msg,0)
       tweet =  elem(msg,1)
       tweeter = elem(msg,2)
       id = elem(msg,3)
       timestamp = elem(msg,4)
       mention_map = Map.get(state,"mentions")
       mention_map =  Map.put(mention_map,mention,[{id,timestamp,tweeter,tweet}])
       state = Map.put(state,"mentions",mention_map)
       {:reply,state,state}
  end

end
