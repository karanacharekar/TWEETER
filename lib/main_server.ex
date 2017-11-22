defmodule MainServer do
    use GenServer

    def start_link() do
        users = %{}
        hashtags = %{}
        mentions = %{}
        state_map = %{"users" => users, "hashtags" => hashtags, "mentions" => mentions}
        {:ok,initial_state} = GenServer.start_link(MainServer, [users,hashtags,mentions], name: :"#{"mainserver"}")   
    end

    def init(initial_state) do
        {:ok,initial_state}
    end

    def get_state(:mainserver) do
        GenServer.call(:mainserver,:get_state)
    end

    def handle_call(:get_state,_from,my_state) do
        {:reply,my_state,my_state}
    end
    
    def create_user(user) do
        GenServer.cast("mainserver",{:add_new_user})
    end

    def check_user(username) do
        current_state = get_state("mainserver")
        user_map = Map.fetch(current_state, "user_map")
        if Map.has_key?(user_map,username) do
            false
        else
            true
        end
    end

    def handle_cast({:add_new_user,user}, my_state) do
        username = Map.fetch(user,"username")
        user_map = Map.fetch(my_state, "users")
        new_state = Map.put(user_map,username,user)
        {:reply,new_state,new_state}
    end
end