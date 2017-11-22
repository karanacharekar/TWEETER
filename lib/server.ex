defmodule Server do
    use Genserver
    
    def main() do   
        GenServer.start_link(MainServer, {}, name: String.to_atom("mainserver"))   
    end

    def init() do
        state_map = %{"users" => %{}, "hashtags" => %{}, "mentions" => %{}}
        {:ok,state}
    end 

end
