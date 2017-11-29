defmodule Mainprog do
   use GenServer
    
    def main() do
        IO.puts "client rchd"
        client_name = "client@" <> get_ip_addr()
        server_name = "server@" <> get_ip_addr()
        Node.start(String.to_atom(client_name))
        Node.set_cookie :"choco"
        Node.connect(String.to_atom(server_name)) 
        IO.inspect Node.list
        testfunc();
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
        #client_name = username <> "@" <> get_ip_addr()
        #IO.puts client_name
        #server_name = "server@" <> get_ip_addr()
        #Node.start(String.to_atom(client_name))
        #Node.set_cookie :"choco"
        #IO.inspect Node.connect(String.to_atom(server_name))
        #IO.inspect Node.list
        server_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"})
        allusers_map = Map.get(server_state,"users")
        if(Map.get(allusers_map,username) == nil) do
            GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:register_user, {username,password}}) 
            IO.puts "user registered"
        else
            IO.puts "Username already exists"
        end
    end


    def serach_hashtag(hashtag) do
        IO.inspect GenServer.call(String.to_atom("mainserver"), {:search_hashtag, {}}) 
    end

    def search_mention(mention)  do
        IO.inspect GenServer.call(String.to_atom("mainserver"), {:search_mentions, {}}) 
    end

    def login(user_name,pass_word) do
        server_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"})
        allusers_map = Map.get(server_state,"users")
        curr_usr_map = Map.get(allusers_map,user_name)
        if(curr_usr_map == nil) do
            IO.puts "User not registered"
        else
            if(Map.get(curr_usr_map,"password") == pass_word) do
                GenServer.start_link(__MODULE__, {user_name,pass_word,{}}, name: String.to_atom(user_name))
                GenServer.call(String.to_atom(user_name), {:create_dashboard_list, {}}) ### CHECK THISSS
                IO.puts "Login succesful"
            else
                IO.puts "Incorrect password"
            end
        end
    end


    def testfunc() do

        weighted_followers = Test.getZipfDist(1000) |> IO.inspect
        hashtaglist = ['#karan','#srishti','#aru','#football','#apple','#mango','#realmadrid','#india','#tweeter','#beer','#rum','#vodka']

        for x <- 1..1000 do
           register_user("user"<> Integer.to_string(x), "pass"<> Integer.to_string(x)) 
           
        end
        
        

        for x <- 1..1000 do
           login("user"<> Integer.to_string(x), "pass" <> Integer.to_string(x)) 
        end
        
        
        

        all_users_list = Test.create_users_list(1000,[])
        num = 1..1000
        num_list = Enum.to_list(num)

        Test.random_tweets_with_hashtag(hashtaglist,100,num_list)
        Test.random_tweets_with_mention(100,num_list)


        for x <- 1..3 do
            spawn fn -> Test.simulate_connect_disconnect(num_list) end
        end

        for x <- 1..1000 do
            weight = round(Enum.at(weighted_followers,x-1))
            Test.random_follow_tweet("user"<>Integer.to_string(x),weight,num_list)
        end



        for x <-1..1000 do
            if(Process.whereis(String.to_atom("user"<>to_string(x))) != nil) do
                retweeter_state = GenServer.call(String.to_atom("user"<>to_string(x)), {:get_state, {}})
            

            dashboard_list = Map.get(retweeter_state,"dashboard")
            size = Enum.count(dashboard_list)
            num_retweets = round(:math.ceil(0.30*size))

            for y <- 1..num_retweets do
                if(Enum.count(dashboard_list)!=0) do
                    retweet = Enum.random(dashboard_list)
                    id = elem(retweet,0)
                    tweeter = elem(retweet,2)
                    dashboard_list = List.delete(dashboard_list, retweet)
                    if("user"<>to_string(x) != tweeter) do
                        if(Process.whereis(String.to_atom("user"<>to_string(x))) != nil) do
                            retweet("user"<>to_string(x),tweeter,id) 
                        end
                    end
                end
            end
            end

        end



    end


    def init(args) do
        username = elem(args,0)
        passwd = elem(args,1)
        state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"})       
        all_users_map = Map.get(state,"users")  
        #IO.inspect all_users_map
        #IO.inspect username
        serv_resp = Map.get(all_users_map, username)
        state = serv_resp
        {:ok,state}
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
    dashboard_list = Enum.sort(dashboard_list,&(elem(&1,2) > elem(&2,2)))
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
        server_state = GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:get_state, "mainserver"}) 
        menion_map = Map.get(server_state,"mentions")
        tweeter_dashboard_list = tweeter_dashboard_list ++ Map.get(state,"tweets")
        Enum.each(tweeter_following_list, fn(n) -> 
                following_state = GenServer.call(String.to_atom(n),{:get_state, "get following peoples tweets"})  
                tweeter_dashboard_list = tweeter_dashboard_list ++ Map.get(following_state,"tweets")
        end)
        tweeter_dashboard_list = tweeter_dashboard_list ++  Map.get(menion_map,"@"<>Map.get(state,"username"))

        if(tweeter_dashboard_list != nil) do
            tweeter_dashboard_list = Enum.sort(tweeter_dashboard_list,&(elem(&1,2) > elem(&2,2)))
        end
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
        if(pid != nil) do
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



defmodule Test do
        


        def getZipfDist(numberofClients) do
            distList=[]
            s=1
            c=getConstantValue(numberofClients,s)
            distList=Enum.map(1..numberofClients,fn(x)->:math.ceil((c*numberofClients)/:math.pow(x,s)) end)
            distList
        end

        def getConstantValue(numberofClients,s) do
            k=Enum.reduce(1..numberofClients,0,fn(x,acc)->:math.pow(1/x,s)+acc end )
            k=1/k
            k
        end

        def simulate_connect_disconnect(num_list) do
            #:timer.sleep(1000)
            
          
            dead = Enum.random(num_list)
            Mainprog.go_offline("user"<>to_string(dead))
            #:timer.sleep(100)
            if(Process.whereis(String.to_atom("user"<>to_string(dead))) == nil) do
                IO.puts "--------------------------------------------------------------------------------------------------------------------------------------"
                IO.puts "user" <> to_string(dead) <> " went offline"
            end
            :timer.sleep(2000)
            Mainprog.go_online("user"<>to_string(dead),"pass"<>to_string(dead))
            if(Process.whereis(String.to_atom("user"<>to_string(dead))) != nil) do
                GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>Mainprog.get_ip_addr())},{:is_online, {"user"<>to_string(dead)}}) 
                IO.puts "--------------------------------------------------------------------------------------------------------------------------------------"
                IO.puts "user" <> to_string(dead) <> " came online"
            end
        end
       
        
        def create_users_list(num,list) do
            if num > 0 do
                user = "user" <> Integer.to_string(num)
                list = list ++ [user]
                create_users_list(num-1,list) 
            else
                list
            end
        end

        def random_tweets_with_hashtag(hashtaglist,num,num_list) do
            cur = Enum.random(num_list)
            cur_user = "user" <> to_string(cur)
            if(Process.whereis(String.to_atom(cur_user)) != nil) do
                    Mainprog.tweet(cur_user,"I am tweet with hashtag " <> Enum.random(hashtaglist))
            end
            random_tweets_with_hashtag(hashtaglist,num-1,num_list)
        end


        def random_tweets_with_mention(num,num_list) do
            cur = Enum.random(num_list)
            cur_user = "user" <> to_string(cur)
            mention = Enum.random(num_list)
            mention_user = "@user"<>mention
            if(curr != mention) do
                if(Process.whereis(String.to_atom(cur_user)) != nil) do
                        Mainprog.tweet(cur_user,"I am tweet with mention " <> "@user" <> Enum.random(num_list))
                end    
                random_tweets_with_mention(num-1,num_list)
            else
                random_tweets_with_mention(num,num_list)
            end

        end

        def random_follow_tweet(cur_user,num,num_list) do
            #IO.puts "curr user is " <> to_string(cur_user)
            if num > 0 do
                to_follow = Enum.random(num_list)
                #IO.inspect to_follow
                if cur_user != "user"<>Integer.to_string(to_follow)  do
                    if(Process.whereis(String.to_atom("user"<> Integer.to_string(to_follow))) != nil) do
                            num_list = List.delete(num_list,to_follow)
                            #IO.inspect num_list
                            Mainprog.follow_someone("user"<> Integer.to_string(to_follow),cur_user)
                    end
                    if(Process.whereis(String.to_atom(cur_user)) != nil) do
                                IO.puts "alive"
                                Mainprog.tweet(cur_user,"I am Tweet")

                    end
                            #IO.puts "hereee"
                            random_follow_tweet(cur_user,num-1,num_list)
                    
                else
                    num_list = List.delete(num_list,to_follow)
                    random_follow_tweet(cur_user,num,num_list)
                end
            
            end
            if(Process.whereis(String.to_atom(cur_user)) != nil) do
                GenServer.call(String.to_atom(cur_user),{:print_state, "someone"}) 
            end
        end



end