defmodule Supervi1 do
    use Supervisor

    def start_link(n) do
        Supervisor.start_link(__MODULE__,n )
    end

    def init(n) do
      children =  worker(Supervi1,[n],[id: "#{n}"])

        supervise(children, strategy: :one_for_one)
    end
 #******************* TOPOLOGIES *******************************

#$$$$$$ FULL $$$$$$$$$$
    def full(algorithm,n,parentid) do
        {:ok,pid}=Node1.Supervisor.start_link(n)
        IO.inspect(pid) #supervisor's pid
        list=Supervisor.which_children(pid)
        child_list=(for x <- list, into: [] do
            {_,cid,_,_}=x
            cid
          end)
        #IO.inspect child_list
        for x <- child_list do
          new_list=List.delete(child_list,x) #Neighbour should not include self
          Actor1.add_neighbours(x,new_list)
        end
        random_node=Enum.random(child_list)
        #node = Map.get(Actor.get_state(random_node),:node)
        IO.inspect(random_node)
        start_time = System.system_time(:millisecond)
        if algorithm == "pushsum" do
            IO.puts "starting Pushsum"
            Actor1.pushsum(random_node,start_time,parentid)
        else
            IO.puts "starting Gossip"
            Actor1.gossip(random_node,start_time,node,parentid)
        end
    end
#$$$$$$ LINE $$$$$$$$$$$$$
    def line(algorithm,n,parentid) do
        {:ok,pid}=Node1.Supervisor.start_link(n)
        IO.inspect(pid) #supervisor's pid
        list=Supervisor.which_children(pid)
        child_list=(for x <- list, into: [] do
            {_,cid,_,_}=x
            cid
          end)
        child_list = Enum.reverse(child_list)
        neigh_indicies = Enum.map(1..n,fn(x)-> case rem(x,n) do
                                                0->[n-1]
                                                1->[2]
                                                _-> [x-1,x+1]
        end end)
        for i<-child_list do
            st = Actor1.get_state(i)
            index = Map.get(st,:node)
            nl = Enum.at(neigh_indicies,index-1)
            neighbours = Enum.map(nl,fn(x)->Enum.at(child_list,x-1) end)
            Actor1.add_neighbours(i,neighbours)
        end
        #for i<-child_list do
        #    IO.inspect Actor1.get_state(i)
        #end
        start_time = System.system_time(:millisecond)
        random_node=Enum.random(child_list)
        state = Actor1.get_state(random_node)
        node = Map.get(state,:node)
         if algorithm == "pushsum" do
            Actor1.pushsum(random_node,start_time,parentid)
        else
            Actor1.gossip(random_node,start_time,node,parentid)
        end
    end
#$$$$$$ HONEY_COMB AND RANDOM_HONEY_COMB  $$$$$$$$$$
    def honeycomb(algorithm,n,parentid) do
        {:ok,pid}=Node1.Supervisor.start_link(n)
        IO.inspect(pid) #supervisor's pid
        list=Supervisor.which_children(pid)
        child_list=(for x <- list, into: [] do
            {_,cid,_,_}=x
            cid
        end)

        child_list = Enum.reverse(child_list)

        neigh_indicies =    Enum.map(1..n,fn(x)->honeyneigh(x) end)
                            |>Enum.map(fn(x)->
                                        temp = Enum.map(x,fn(y)->   if y<0 or y>n do
                                                                        0
                                                                    else
                                                                        y end end)
                                temp=temp--[0] end )


        Enum.each(child_list,fn(i)->    st =Actor1.get_state(i)
                                        index = Map.get(st,:node)
                                        nl = Enum.at(neigh_indicies,index-1)
                                        neighbours = Enum.map(Enum.at(neigh_indicies,index-1),fn(x)->Enum.at(child_list,x-1) end)
                                        Actor1.add_neighbours(i,neighbours) end)

        for i<-child_list do
            st =Actor1.get_state(i)
            #IO.inspect st
        end
        start_time = System.system_time(:millisecond)
        random_node=Enum.random(child_list)
        state = Actor1.get_state(random_node)
        node = Map.get(state,:node)
         if algorithm == "pushsum" do
            Actor1.pushsum(random_node,start_time,parentid)
        else
            Actor1.gossip(random_node,start_time,node,parentid)
        end
    end
    def randomhoneycomb(algorithm,n,parentid) do
        {:ok,pid}=Node1.Supervisor.start_link(n)
        IO.inspect(pid) #supervisor's pid
        list=Supervisor.which_children(pid)
        child_list=(for x <- list, into: [] do
            {_,cid,_,_}=x
            cid
        end)

        child_list = Enum.reverse(child_list)

        neigh_indicies =    Enum.map(1..n,fn(x)->honeyneigh(x) end)
                            |>Enum.map(fn(x)->
                                        temp = Enum.map(x,fn(y)->   if y<0 or y>n do
                                                                        0
                                                                    else
                                                                        y end end)
                                temp=temp--[0] end )
        mid = round(n/2)
        neigh_indicies_first = Enum.map(1..mid,fn(x)-> Enum.at(neigh_indicies,x-1)++[x+mid] end)
        neigh_indicies_last = Enum.map(mid+1..n,fn(x)-> Enum.at(neigh_indicies,x-1)++[x-mid] end)
        random_neighbours = Enum.map(neigh_indicies,fn(x)->List.last(x) end)
        neigh_indicies = neigh_indicies_first++neigh_indicies_last
        #IO.inspect neigh_indicies_first
        #IO.inspect neigh_indicies
        Enum.each(child_list,fn(i)->    st =Actor1.get_state(i)
                                        index = Map.get(st,:node)
                                        nl = Enum.at(neigh_indicies,index-1)
                                        neighbours = Enum.map(Enum.at(neigh_indicies,index-1),fn(x)->Enum.at(child_list,x-1) end)
                                        Actor1.add_neighbours(i,neighbours) end)


        start_time = System.system_time(:millisecond)
        random_node=Enum.random(child_list)
        state = Actor1.get_state(random_node)
        node = Map.get(state,:node)
         if algorithm == "pushsum" do
            Actor1.pushsum(random_node,start_time,parentid)
        else
            Actor1.gossip(random_node,start_time,node,parentid)
        end
    end
#$$$$$$$$$$$ RANDOM_2D $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    def random2d(algorithm,n,parentid) do
        {:ok,pid}=Node1.Supervisor.start_link(n)
        IO.inspect(pid) #supervisor's pid
        list=Supervisor.which_children(pid)
        child_list=(for x <- list, into: [] do
            {_,cid,_,_}=x
            cid
        end)

        child_list = Enum.reverse(child_list)
        list =[]
        list = Enum.map(1..n, fn _ -> list++[:rand.uniform(), :rand.uniform()] end)
        #IO.inspect list
        x =  Enum.map(1..n,fn(x)->Enum.map(1..n,fn(y)->
                x1 = List.first(Enum.at(list,x-1))
                x2 = List.first(Enum.at(list,y-1))
                y1 = Enum.at(list,x-1)|>List.last()
                y2 = Enum.at(list,x-1)|>List.last()
                distance =   :math.sqrt(:math.pow(x1-x2,2)+:math.pow(y1-y2,2))
        if distance < 0.1 and distance != 0 do
            y
        end end)end)
        neigh_indicies = Enum.map(x,fn(x)-> t = Enum.uniq(x)--[nil] end)
        for i<- child_list do
                                        st =Actor1.get_state(i)
                                        index = Map.get(st,:node)
                                        nl = Enum.at(neigh_indicies,index-1)
                                        neighbours = Enum.map(nl,fn(x)->Enum.at(child_list,x-1) end)
                                        Actor1.add_neighbours(i,neighbours) end
        start_time = System.system_time(:millisecond)
        random_node=Enum.random(child_list)
        state = Actor1.get_state(random_node)
        node = Map.get(state,:node)
         if algorithm == "pushsum" do
            Actor1.pushsum(random_node,start_time,parentid)
        else
            Actor1.gossip(random_node,start_time,node,parentid)
        end
    end
#******************************************************************
    def honeyneigh(n) do
        val = rem(n,5)
        #  IO.puts val
            l = if rem(n,2)==0 do
                        case val do
                            0->[n-1,n+5]
                            1->[n+1,n+5]
                            _->[n-1,n+5,n+1]
                        end
                else
                        case val do
                            0->[n-1,n-5]
                            1->[n+1,n-5]
                            _->[n-1,n-5,n+1]
                        end
                end
    end

#$$$$$$$$$$$$$$$$$$$$$$ THREED $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


def threedtorus(algorithm,n,parentid) do
  {:ok,pid}=Node1.Supervisor.start_link(n)
  IO.inspect(pid) #supervisor's pid
  list=Supervisor.which_children(pid)
  child_list=(for x <- list, into: [] do
      {_,cid,_,_}=x
      cid
  end)

  child_list = Enum.reverse(child_list)
  neigh_indicies = Enum.map(1..n,fn(x)->t_neigh(x,n) end)
  IO.inspect neigh_indicies
      for i<- child_list do
          st =Actor1.get_state(i)
          index = Map.get(st,:node)
          nl = Enum.at(neigh_indicies,index-1)
          neighbours = Enum.map(nl,fn(x)->Enum.at(child_list,x-1) end)
          #IO.puts "index   #{index}   Neighbours  #{inspect(nl)}   "
      #    :timer.sleep(2000)
          Actor1.add_neighbours(i,neighbours)
      end
      start_time = System.system_time(:millisecond)
                                  random_node=Enum.random(child_list)
                                  state = Actor1.get_state(random_node)
                                  node = Map.get(state,:node)
                                   if algorithm == "pushsum" do
                                     IO.puts "starting pushsum"
                                      Actor1.pushsum(random_node,start_time,parentid)
                                  else
                                      Actor1.gossip(random_node,start_time,node,parentid)
                                  end
end

  def t_neigh(n,max) do

    limit = max - 25;
    y = if(n < 26) do
          less_than(n,max)

        else

          if (n > limit) do
            greater_than(n,max)

      else
        v = rem(n,25)
        v1 = rem(rem(n,25),5)

        cond  do

          #Calculating neighbours for 50,limit and 100...
          v == 0 ->  [n-5,n-25,n+25,n-1,n-20,n-4]

          #Calculating neighbours for 27-29 and 52-54
          v > 1 and v < 5  ->   [n-1,n+1,n+25,n-25,n+5,n+20]

          #Calculating neighbours for 47-49 and 72-74
          v > 21 and v <25 ->  [n-1,n+1,n-25,n+25,n-2,n+20]

          #Calculating neighbours for 26, 51 and 76
          v == 1 -> [n-25,n+25,n+1,n+5,n+4,n+20]

          #Calculating neighbours for 30, 55 and 80
          v == 5 ->  [n-1,n+5,n-25,n+25,n+20,n-4]

          #Calculating neighbours for 46, 71 and 96
          v == 21 ->  [n-25,n-5,n-25,n+1,n-20,n+4]

          #Calculating neighbours for 35,40,45 and 60, 65, 70
          v1 == 0 ->  [n-25,n+25,n-5,n+5,n-1,n-4]

          #Calculating neighbours for 31,36,41 and 56,61,66
          v1 == 1 ->  [n-25,n+25,n-5,n+5,n+1,n+4]

          #Calculating all internal neighbours
          true ->  [n-1,n+1,n+5,n-5,n+25,n-25]
        end
      end
  end
end

  def less_than(n,max) do

    limit = max-25

    remainder = rem(n,5)
    quotient = div(n,5)


    cond do
      remainder == 0 ->
        #Calculating neighbours for 5,10,15,20 and 25
        case quotient do
          1 ->  [n-1,n+5,n+25,n-4,n+20,n+limit]
          5 ->  [n-1,n-5,n+25,n-20,n-4,n+limit]
          _ ->  [n-1,n-5,n+5,n+25,n-4,n+limit]
        end

      remainder == 1 ->
        #Calculating neighbours for 1, 6, 11, 16, and 21
        case quotient do
          0 ->  [n+1,n+5,n+25,n+4,n+20,n+limit]
          4 ->  [n+1,n-5,n+25,n+4,n-20,n+limit]
          _ ->  [n+1,n+5,n-5,n+4,n+25,n+limit]
        end

      quotient  == 0 and n != 1 ->
          #Calculating neighbours for 2,3 and 4
          case remainder do
            _ -> [n-1,n+1,n+5,n+25,n+20,n+limit]
          end

      n > 21 ->
        #Calculating neighbours for 22, 23 and 24
        case quotient do
          _ ->  [n-1,n+1,n-5,n+25,n-20,n+limit]
        end
        #Calculating 7-9, 12-15, and 17-19
        true ->  [n-1,n-5,n+5,n+1,n+25,n+limit]

      end
      end

      def greater_than(n,max) do

        limit = max - 25
        remainder = rem(n,5)
        quotient = div(n,5)
        val = rem(div(n,5),5)

        cond do
          remainder == 0 ->
            #Calculating neighbours for 80,85,90, 95 and 100
            case val do
              1 ->  [n-1,n+5,n-25,n-4,n+20,n-limit]
              0 ->  [n-1,n-5,n-25,n-20,n-4,n-limit]
              _ ->  [n-1,n-5,n+5,n-25,n-4,n-limit]
            end

          remainder == 1 ->
            #Calculating neighbours for  76, 81, 86, 91 and 96
            case val do
              0 ->  [n+1,n+5,n-25,n+4,n+20,n-limit]
              4 ->  [n+1,n-5,n-25,n-4,n-20,n-limit]
              _ ->  [n+1,n+5,n-5,n+4,n-25,n-limit]
            end

          val  == 0 and n != 76 ->
              #Calculating neighbours for 77, 78 and 79
              case remainder do
                _ ->  [n-1,n+1,n-5,n-25,n+20,n-limit]
              end

          n > 96 ->
              #Calculating neighbours for 97, 98 and 99
              case quotient do
                _ ->  [n-1,n+1,n-5,n-25,n-20,n-limit]
              end

              #Calculating 82-84, 87-89, and 92-94
          true ->  [n-1,n-5,n+5,n+1,n-25,n-limit]

          end
      end
end
