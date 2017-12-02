defmodule Mainprog do
   use GenServer
    
    def main(numClients) do
        IO.puts "client rchd"
        client_name = "client@" <> get_ip_addr()
        server_name = "server@" <> get_ip_addr()
        Node.start(String.to_atom(client_name))
        Node.set_cookie :"choco"
        Node.connect(String.to_atom(server_name)) 
        IO.inspect Node.list
        testfunc(numClients);
        #IO.puts "####################################"
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

    def register_user(username,password) do

        server_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"})
        allusers_map = Map.get(server_state,"users")
        if(Map.get(allusers_map,username) == nil) do
            GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:register_user, {username,password}}) 
            IO.puts "user registered"
        else
            IO.puts "Username already exists"
        end
    end


    

    def login(user_name,pass_word,weight,numClients) do
        IO.puts "login func"
        server_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"})
        IO.inspect server_state
        IO.puts "karan"
        allusers_map = Map.get(server_state,"users")
        curr_usr_map = Map.get(allusers_map,user_name)
        
        if(curr_usr_map == nil) do
            IO.puts "User not registered"
        else
            if(Map.get(curr_usr_map,"password") == pass_word) do
                IO.puts "pasword matched"
                GenServer.start_link(__MODULE__, {user_name,pass_word,weight,{}}, name: String.to_atom(user_name))
                create_dashboard_list(user_name)
                IO.puts "back"
                spawn fn -> Simulator.main(user_name,weight,numClients) end
                ### CHECK THISSS
                IO.puts "Login succesful"
            else
                IO.puts "Incorrect password"
            end
        end

    end


    def testfunc(numClients) do
        weighted_followers = getZipfDist(numClients) |> IO.inspect

        for x <- 1..numClients do
           register_user("user"<> Integer.to_string(x), "pass"<> Integer.to_string(x)) 
        end
        

        for x <- 1..numClients do
            weight = round(Enum.at(weighted_followers,x-1))
            login("user"<> Integer.to_string(x), "pass" <> Integer.to_string(x),weight,numClients) 
        end
        

        :timer.sleep(10000)
        for x <- 1..numClients do
            spawn fn -> IO.inspect GenServer.call(String.to_atom("user"<>to_string(x)), {:print_state,"printing"}) end
            :timer.sleep(1000)
        end

        
    end


    def init(args) do
        IO.puts "login def"
        username = elem(args,0)
        passwd = elem(args,1)
        weight = elem(args, 2)
        state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"})       
        all_users_map = Map.get(state,"users")  
        serv_resp = Map.get(all_users_map, username)
        state = serv_resp
        {:ok,state}
    end 


    def create_dashboard_list(user_name) do
        IO.puts "inside dash"
        GenServer.call(String.to_atom(user_name), {:create_dashboard_list, {}})
    end


    def go_online(user_name,pass_word) do
        GenServer.start_link(__MODULE__, {user_name,pass_word,{}}, name: String.to_atom(user_name))
        GenServer.call(String.to_atom(user_name), {:create_dashboard_list, {}}) ### CHECK THISSS
    end

    
    def retweet(tweeter,someone,id) do
        #IO.puts "retweeting"
        {tweeter,retweet_tweet} = GenServer.call(String.to_atom(tweeter), {:retweet, {someone,id}}) #add the retweeted tweet to tweeter's tweet list        
        tweet(tweeter,retweet_tweet) 
    end


    def follow_someone(tweeter,someone) do
        pid = Process.whereis(String.to_atom(someone))
        if(pid != nil && Process.alive?(pid) == true) do
            #IO.puts "keyur is alive"
            GenServer.call(String.to_atom(someone), {:follow_someone_alive, {tweeter}}) #add tweeter(user) to the followers list of person he follows
            GenServer.call(String.to_atom(tweeter), {:follow_someone, {someone}}) #add the person whom user follows to users following list
            GenServer.call(String.to_atom(tweeter), {:add_tweets_following_alive, {someone}})
        else
            GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:follow_someone_dead, {tweeter}}) #add tweeter(user) to the followers list of person he follows
            GenServer.call(String.to_atom(tweeter), {:follow_someone, {someone}}) #add the person whom user follows to users following list
            GenServer.call(String.to_atom(tweeter), {:add_tweets_following_dead, {someone}})
    end
        #GenServer.call(String.to_atom(someone), {:tweet, {tweet}})
    end


    def search_hashtag(hashtag) do
        server_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"}) 
        all_hashtags_map = Map.get(server_state,"hashtags")
        hashtag_tweets = Map.get(all_hashtags_map,hashtag)
        IO.inspect hashtag_tweets
    end


    def search_mention(mention) do
        server_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"})  
        all_mentions_map = Map.get(server_state,"mentions")
        mention_tweets = Map.get(all_mentions_map,mention)
        IO.inspect mention_tweets
    end

    def tweet(tweeter,tweet) do
        #IO.puts "send tweet"
        {id,timestamp} = GenServer.call(String.to_atom(tweeter), {:tweet, {tweet}})
        parse_tweet(tweeter,tweet,id,timestamp)
    end 

    def go_offline(username) do 
        #state = GenServer.call(String.to_atom("mainserver"),{:get_state,"mainserver"})
        #IO.puts username <> " going offline"
        user_state =  GenServer.call(String.to_atom(username),{:get_state,"user"})
        user_state = Map.put(user_state,"dashboard",[])
        IO.inspect user_state
        GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:go_offline, {username,user_state}})
        IO.puts "done"
        #GenServer.call(String.to_atom(username), {:kill_user, {}}) 
        
        pid = Process.whereis(String.to_atom(username))
        #Process.exit(pid,:kill)
        
        IO.inspect pid
        GenServer.stop(pid,:normal) 
        #Process.exit(pid,:normal) 
        pid = Process.whereis(String.to_atom(username))
        IO.inspect pid
        if(pid == nil) do
            #IO.puts username <> " killed"
            Node.disconnect("server@"<>get_ip_addr())
        else
            #IO.puts username <> " still alive"
        end 


    end

    def getZipfDist(numberofClients) do
            distList=[]
            s=1
            c= Test.getConstantValue(numberofClients,s)
            distList=Enum.map(1..numberofClients,fn(x)->:math.ceil((c*numberofClients)/:math.pow(x,s)) end)
            distList
        end


    def parse_tweet(tweeter,tweet,id,timestamp) do

        state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"})  
        split_tweet = String.split(tweet);
        
        Enum.each(split_tweet, fn(n) -> 
            word = n
            if(String.first(word)=="#") do
                #IO.puts "parsing"
                hashtag_map = Map.get(state,"hashtags")
                #IO.inspect hashtag_map
                if(Map.get(hashtag_map,word) == nil) do
                    GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:add_new_hashtag, {word,tweet,tweeter,id,timestamp}})
                else
                    GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:add_hashtag, {word,tweet,tweeter,id,timestamp}})
                end
            end

            if(String.first(word)=="@") do
                
                mention_map = Map.get(state,"mentions")
                #IO.inspect mention_map
                #IO.puts "mention"
                if(Map.get(mention_map,word)==nil) do
                  #IO.puts "mention inside"
                  GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:add_new_mention, {word,tweet,tweeter,id,timestamp}})
                else 
                  GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:add_mention, {word,tweet,tweeter,id,timestamp}})
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


  def handle_call({:search_hashtag ,new_message},_from,state) do 
    all_hashtags = Map.get(state,"hashtags")
    query_hashtag = elem(new_message,0)
    reqd_hashtag_list = Map.get(all_hashtags,query_hashtag)
    if(reqd_hashtag_list == nil) do
        IO.puts "required hashtag does not exist"
    end
    {:reply,reqd_hashtag_list,state}
  end

  def handle_call({:search_mention ,new_message},_from,state) do 
    all_mentions = Map.get(state,"mentions")
    query_mention = elem(new_message,0)
    reqd_mention_list = Map.get(all_mentions,query_mention)
    if(reqd_mention_list == nil) do
        IO.puts "required mention does not exist"
    end
    {:reply,reqd_mention_list,state}
  end

  def handle_call({:add_tweets_following_alive ,new_message},_from,state) do 
    #IO.inspect state 
    someone = elem(new_message, 0)

    someone_state = GenServer.call(String.to_atom(someone),{:get_state, "someone"})
    someone_tweet_list = Map.get(someone_state,"tweets")
    dashboard_list = Map.get(state,"dashboard")
    
    dashboard_list = dashboard_list ++ someone_tweet_list 
   
    dashboard_list = Enum.sort(dashboard_list,&(elem(&1,2) > elem(&2,2)))
    state = Map.put(state, "dashboard", dashboard_list)
    {:reply,state,state}
  end


  def handle_call({:add_tweets_following_dead ,new_message},_from,state) do 
    #IO.inspect state 
    someone = elem(new_message, 0)
    mainserv_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"})
    all_users_map = Map.get(mainserv_state,"users")
    someone_state = Map.get(all_users_map,someone)
    someone_tweet_list = Map.get(someone_state,"tweets")
    dashboard_list = Map.get(state,"dashboard")
    dashboard_list = dashboard_list ++ someone_tweet_list 
    if(dashboard_list != nil ) do
    dashboard_list = Enum.sort(dashboard_list,&(elem(&1,2) > elem(&2,2)))
    end
    state = Map.put(state, "dashboard", dashboard_list)
    {:reply,state,state}
  end


  def handle_call({:create_dashboard_list,new_message},_from,state) do  
    
    tweeter_following_list = Map.get(state,"following")
    tweeter_dashboard_list = Map.get(state,"dashboard")
    tweeter_follower_list = Map.get(state,"followers")
    if(Enum.empty?(tweeter_following_list) && Enum.empty?(tweeter_follower_list) && Enum.empty?(tweeter_dashboard_list)) do
        IO.puts " First time login "
    else
        server_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"}) 
        menion_map = Map.get(server_state,"mentions")
        tweeter_dashboard_list = tweeter_dashboard_list ++ Map.get(state,"tweets")
        Enum.each(tweeter_following_list, fn(n) -> 
                following_state = GenServer.call(String.to_atom(n),{:get_state, "get following peoples tweets"})  
                tweeter_dashboard_list = tweeter_dashboard_list ++ Map.get(following_state,"tweets")
        end)
        
        tweeter_dashboard_list = tweeter_dashboard_list ++  Map.get(menion_map,"@"<>Map.get(state,"username"))
        IO.inspect tweeter_dashboard_list

        # if(tweeter_dashboard_list != nil) do
        #     IO.puts "reached inside"
        #     tweeter_dashboard_list = Enum.sort(tweeter_dashboard_list,&(elem(&1,2) > elem(&2,2)))
        # end
    end
    {:reply,state,state}
  end


  def handle_call({:retweet ,new_message},_from,state) do  
    
    someone = elem(new_message,0)
    tweet_id = elem(new_message,1)
    #IO.puts "still retweeting"
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

   
   



  def handle_call({:tweet, new_message},_from,state) do
    #IO.puts Map.get(state,"username") <> "sending tweet"
    tweet = elem(new_message,0)
    tweeter = Map.get(state,"username")
    tweets_list = Map.get(state,"tweets")
    follower_list = Map.get(state,"followers") 
    dashboard_list = Map.get(state,"dashboard")
    #IO.puts "still sending tweet"
    
    if List.last(tweets_list) == nil do
        last_tweet_id = -1
    else
        {last_tweet_id,_,_,_} = List.last(tweets_list)    
    end
    #IO.inspect last_tweet_id
    timestamp = :os.system_time(:millisecond)

    tweets_list = tweets_list ++ [{last_tweet_id+1,timestamp,tweeter,tweet}]
    dashboard_list = dashboard_list ++ [{last_tweet_id+1,timestamp,tweeter,tweet}]


    #IO.inspect tweets_list
   
    state = Map.put(state,"tweets",tweets_list)
    state = Map.put(state, "dashboard", dashboard_list)
    Enum.each(follower_list, fn(n) ->
        pid = Process.whereis(String.to_atom(n))
        if(pid != nil && n != tweeter) do
            GenServer.call(String.to_atom(n), {:tweet_someone_alive, {last_tweet_id+1,timestamp,tweeter,tweet}})
        end
    end)
    #IO.puts "tweet sent"
    {:reply,{last_tweet_id+1,timestamp},state}
  end

  def handle_call({:tweet_someone_alive, new_message},_from,state) do
       #IO.puts "tweet someone alive"
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





        
        


