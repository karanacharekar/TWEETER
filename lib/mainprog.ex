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
            IO.puts username <> " registered"
        else
            IO.puts "Username already exists"
        end
    end


    

    def login(user_name,pass_word,weight,numClients) do
        #IO.puts "login func"
        server_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"})
        #IO.inspect server_state
        #IO.puts "karan"
        allusers_map = Map.get(server_state,"users")
        curr_usr_map = Map.get(allusers_map,user_name)
        
        if(curr_usr_map == nil) do
            IO.puts "User not registered"
            #spawn fn -> register_user(user_name,pass_word) end
        else
            if(Map.get(curr_usr_map,"password") == pass_word) do
                #IO.puts "pasword matched"
                GenServer.start_link(__MODULE__, {user_name,pass_word,weight,{}}, name: String.to_atom(user_name))
                create_dashboard_list(user_name)
                #IO.puts "back"
                IO.puts "Login succesful" <> user_name
            else
                IO.puts "Incorrect password"
            end
        end

    end


    def testfunc(numClients) do
        weighted_followers = getZipfDist(numClients) |> IO.inspect
        sum = round(Enum.sum(weighted_followers))
        IO.puts sum
        hashtaglist = ["#karan","#srishti","#aru","#football","#apple","#mango","#realmadrid","#india","#tweeter","#beer","#rum","#vodka","#dos","#distributed","#yes","#no"]


        for x <- 1..numClients do
           register_user("user"<> Integer.to_string(x), "pass"<> Integer.to_string(x)) 
        end
        
        for x <- 1..numClients do
            weight = round(Enum.at(weighted_followers,x-1))
            login("user"<> Integer.to_string(x), "pass" <> Integer.to_string(x),weight,numClients)
        end
        

        
        all_users_list = Test.create_users_list(numClients,[])
        num = 1..numClients
        num_list = Enum.to_list(num)

        for x <- 1..numClients do
            spawn fn -> Test.random_follow("user"<> Integer.to_string(x),Enum.at(weighted_followers,x-1), num_list) end
            spawn fn -> Test.random_tweet("user"<> Integer.to_string(x),Enum.at(weighted_followers,x-1)*60, num_list) end

        end 

        spawn fn -> Test.simulate_connect_disconnect(num_list) end
        spawn fn -> Test.simulate_connect_disconnect(num_list) end
        spawn fn -> Test.simulate_connect_disconnect(num_list) end


        Test.random_tweets_with_hashtag(hashtaglist,numClients*3,num_list) 
        Test.random_tweets_with_mention(numClients*3,num_list) 


        # for x <- 1..numClients do
        #     spawn fn -> Test.random_tweet("user"<> Integer.to_string(x),Enum.at(weighted_followers,x-1)*2, num_list) end
        # end



        for x <- 1..numClients do
            spawn fn -> Test.sim_retweet("user"<> Integer.to_string(x)) end
        end

        
      
       
        #spawn fn -> Test.simulate_connect_disconnect(num_list) end
        




        spawn fn -> GenServer.call(String.to_atom("user10"), {:print_state,"printing"})end
        spawn fn -> GenServer.call(String.to_atom("user40"), {:print_state,"printing"}) end
        spawn fn -> GenServer.call(String.to_atom("user1"), {:print_state,"printing"})end

        # for x <- 1..numClients do
        #     spawn fn -> Simulator.main("user"<> Integer.to_string(x),Enum.at(weighted_followers,x-1),numClients) end
        # end

        :timer.sleep(3000)
    
        IO.puts ""
        IO.puts "Result for querying for hashtag #realmadrid"
        IO.puts "----------------------------------------------------------"
        Mainprog.search_hashtag("#realmadrid") 
    

        IO.puts ""
        IO.puts "Result for querying for user300's mention" 
        IO.puts "----------------------------------------------------------"
        Mainprog.search_mention("@user300") 
        IO.puts ""
        IO.puts ""
        # :timer.sleep(10000)
        # for x <- 1..numClients do
        #     spawn fn -> IO.inspect GenServer.call(String.to_atom("user"<>to_string(x)), {:print_state,"printing"}) end
        #     :timer.sleep(1000)
        # end

        
    end


    def init(args) do
        #IO.puts "login def"
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
        #   IO.puts "inside dash"
        GenServer.call(String.to_atom(user_name), {:create_dashboard_list, {}})
    end


    def go_online(user_name,pass_word) do
        GenServer.start_link(__MODULE__, {user_name,pass_word,{}}, name: String.to_atom(user_name))
        GenServer.call(String.to_atom(user_name), {:create_dashboard_list, {}})
        GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>Mainprog.get_ip_addr())},{:is_online, {user_name}}) 
 ### CHECK THISSS
    end

    
    def retweet(tweeter,someone,id) do
        #IO.puts "retweeting"
        someone_state = GenServer.call(String.to_atom(someone),{:get_state, "someone"})
        {tweeter,retweet_tweet} = GenServer.call(String.to_atom(tweeter), {:retweet, {someone,id,someone_state}}) #add the retweeted tweet to tweeter's tweet list        
        retweet_tweet = "retweet: " <> retweet_tweet 
        tweet(tweeter,retweet_tweet) 
    end


    def follow_someone(tweeter,someone) do
        IO.puts tweeter <> " following " <> someone
        pid = Process.whereis(String.to_atom(someone))
        someone_state = GenServer.call(String.to_atom(someone),{:get_state, "someone"}) 
        mainserv_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"})

        if(pid != nil && Process.alive?(pid) == true) do
            #IO.puts "keyur is alive"
            GenServer.call(String.to_atom(someone), {:follow_someone_alive, {tweeter}}) #add tweeter(user) to the followers list of person he follows
            GenServer.call(String.to_atom(tweeter), {:follow_someone, {someone}}) #add the person whom user follows to users following list
            GenServer.call(String.to_atom(tweeter), {:add_tweets_following_alive, {someone,someone_state}})
        else
            GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:follow_someone_dead, {tweeter}}) #add tweeter(user) to the followers list of person he follows
            GenServer.call(String.to_atom(tweeter), {:follow_someone, {someone}}) #add the person whom user follows to users following list
            GenServer.call(String.to_atom(tweeter), {:add_tweets_following_dead, {someone,mainserv_state}})
    end
        #GenServer.call(String.to_atom(someone), {:tweet, {tweet}})
    end


    def search_hashtag(hashtag) do
        server_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"},:infinity) 
        all_hashtags_map = Map.get(server_state,"hashtags")
        hashtag_tweets = Map.get(all_hashtags_map,hashtag)
        IO.inspect hashtag_tweets
    end


    def search_mention(mention) do
        server_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"},:infinity)  
        all_mentions_map = Map.get(server_state,"mentions")
        mention_tweets = Map.get(all_mentions_map,mention)
        IO.inspect mention_tweets
    end

    def tweet(tweeter,tweet) do
        #IO.puts "send tweet" 
        IO.puts tweeter <> "sending tweet " <> tweet
        {id,timestamp} = GenServer.call(String.to_atom(tweeter), {:tweet, {tweet}})
        parse_tweet(tweeter,tweet,id,timestamp)
    end 

    def go_offline(username) do 
        IO.puts "**********" <> username <> "****** trying to go offline"
        #state = GenServer.call(String.to_atom("mainserver"),{:get_state,"mainserver"})
        #IO.puts username <> " going offline"
        user_state =  GenServer.call(String.to_atom(username),{:get_state,"user"})
        user_state = Map.put(user_state,"dashboard",[])
        IO.inspect user_state
        spawn fn -> GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:go_offline, {username,user_state}}) end
        IO.puts "========================================================="
        IO.puts "done"
        #GenServer.call(String.to_atom(username), {:kill_user, {}}) 
        
        pid = Process.whereis(String.to_atom(username))
        #Process.exit(pid,:kill)
        
        IO.inspect pid
        GenServer.stop(pid,:normal) 
        Process.exit(pid,:normal) 
        pid = Process.whereis(String.to_atom(username))
        IO.inspect pid
        
        if(pid == nil) do
            GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>Mainprog.get_ip_addr())},{:is_offline, {username}}) 
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
    someone_state = elem(new_message,1)
    if(Process.whereis(String.to_atom(someone))) do
        
        someone_tweet_list = Map.get(someone_state,"tweets")
        dashboard_list = Map.get(state,"dashboard")
        
        dashboard_list = dashboard_list ++ someone_tweet_list 
    
        dashboard_list = Enum.sort(dashboard_list,&(elem(&1,2) > elem(&2,2)))
        state = Map.put(state, "dashboard", dashboard_list)
    end
    {:reply,state,state}
  end


  def handle_call({:add_tweets_following_dead ,new_message},_from,state) do 
    #IO.inspect state 
    someone = elem(new_message, 0)
    mainserv_state = elem(new_message,1)
    #mainserv_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"})
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
        #IO.puts " First time login "
    else
        server_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"},:infinity) 
        menion_map = Map.get(server_state,"mentions")
        tweeter_dashboard_list = tweeter_dashboard_list ++ Map.get(state,"tweets")
        Enum.each(tweeter_following_list, fn(n) -> 
                tweeter_dashboard_list = Map.get(state,"dashboard")
                if Process.whereis(String.to_atom(n)) != nil do
                following_state = GenServer.call(String.to_atom(n),{:get_state, "get following peoples tweets"},:infinity)  
                tweeter_dashboard_list = tweeter_dashboard_list ++ Map.get(following_state,"tweets")
                state = Map.put(state,"dashboard",tweeter_dashboard_list)
                end
        end)
        
        tweeter_dashboard_list = Map.get(state,"dashboard")
        if(Map.get(menion_map,"@"<>Map.get(state,"username")) != nil) do
            tweeter_dashboard_list = tweeter_dashboard_list ++  Map.get(menion_map,"@"<>Map.get(state,"username"))
        end
        state = Map.put(state,"dashboard",tweeter_dashboard_list)
        #IO.inspect tweeter_dashboard_list

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
    someone_state = elem(new_message,2)
    #IO.puts "still retweeting"
    
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
            spawn fn -> GenServer.call(String.to_atom(n), {:tweet_someone_alive, {last_tweet_id+1,timestamp,tweeter,tweet}}) end
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





        
        


