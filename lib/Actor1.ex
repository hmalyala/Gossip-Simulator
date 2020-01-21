defmodule Node1.Supervisor do
    use Supervisor
    def start_link(n) do
        {myInt, _} = :string.to_integer(to_charlist(n))
        Supervisor.start_link(__MODULE__,n )
    end

    def init(myInt) do
       children =Enum.map(1..myInt, fn(s) ->
            #IO.puts "I am in supervisor init"
            worker(Actor1,[s],[id: "#{s}"])
            end)
        supervise(children, strategy: :one_for_one)
    end
end

###############################################################################################################################################

defmodule Actor1 do
    use GenServer

    def start_link(index) do
        GenServer.start_link(__MODULE__,index)
    end


    def init(index) do
        state = %{:s=>index,:node=>index,:weight=>1.0,:pid=>self(),:neighbour_list=>[],:c=>0,:time =>0}
        {:ok,state}
    end


    def add_neighbours(pid,neighbours) do
        GenServer.cast(pid,{:addneighbours, neighbours})
    end

    def super_receive(pid) do
        state = GenServer.call(pid,{:state})
        state
    end

    def get_state(pid) do
        GenServer.call(pid, {:state})
    end

    def gossip(pid,start_time,i,parentid) do

        acstate = get_state(pid)
        #IO.inspect(acstate)
        count = Map.get(acstate,:c)
        if count<10 do
            GenServer.cast(pid,{:transmit,start_time,i,parentid})
        end
    end

    def pushsum(pid,start_time,parentid) do
        state = get_state(pid)
        #IO.inspect state
        index = Map.get(state,:node)
        s = Map.get(state,:s)
        w = Map.get(state,:weight)
        nextNode = Enum.random(Map.get(state,:neighbour_list))
        #IO.puts "#{s}   #{w/2}    #{inspect(nextNode)}"
        GenServer.cast(pid,{:updatesw,s/2,w/2})
        GenServer.cast(nextNode,{:transmitpush,[s/2,w/2,index],start_time,parentid})
    end

    def update_neighbours(neighbourlist,pid) do
        Enum.each(neighbourlist,fn(x)->GenServer.cast(x,{:updateneighbours,pid}) end)
    end

#*************************************************************************************************************************

    def handle_cast({:updatesw,s,w},state) do
        state = Map.put(state,:s,s)
        state = Map.put(state,:weight,w)
        {:noreply,state}
    end



    def handle_cast({:updateneighbours,pid},state) do
        list= Map.get(state,:neighbour_list)
        state = Map.put(state,:neighbour_list,list--[pid])
        {:noreply,state}
    end

    def handle_call({:state},_from,state) do
        {:reply,state,state}
    end

    def handle_cast({:addneighbours,neighbours},state) do
        state =  Map.put(state, :neighbour_list, neighbours)
        {:noreply,state}
    end

    def handle_cast({:updatetime,time},state) do
        state = Map.put(state,:time,time)
        {:noreply,state}
    end

    def handle_cast({:updatecount,ncount},state) do
        state = Map.put(state,:c,ncount)
        {:noreply,state}
    end

    def handle_cast({:transmit,start_time,i,parentid},state) do
        sender_index = i
        [nodeindex,pid,count] = [Map.get(state,:node),Map.get(state,:pid),Map.get(state,:c)]
        val = sender_index==nodeindex


        if count<10 do
            #if not val do IO.puts "Sender #{sender_index} Receiver #{nodeindex} count changed from #{count} to #{count+1} "
            #    else
            #    IO.puts "Sender #{sender_index} Receiver #{nodeindex} No change in count"
            #end
            #IO.puts "I am in Gossip node : #{nodeindex}  count : #{count}"
            nextNode=Enum.random(Map.get(state,:neighbour_list))
            GenServer.cast(nextNode,{:transmit,start_time,nodeindex,parentid})
            :timer.sleep(200)
            GenServer.cast(pid,{:transmit,start_time,nodeindex,parentid})
            if count==9 and val do
                time = System.system_time(:millisecond)-start_time
                GenServer.cast(pid,{:updatetime,time})
                IO.puts "Node #{nodeindex} converged with time #{time}"
                send(parentid, {:from_child, self()})
            end

        end
        newcount = if sender_index==nodeindex do
                        count+1
                    else
                        count
                    end
        {:noreply,Map.put(state,:c,newcount)}
    end

    def handle_cast({:transmitpush,new_sw,start_time,parentid},state) do
        [sender_s,sender_w,sender] = new_sw
        #IO.puts "#{sender_s}   #{sender_w}   #{sender}"
        pid = Map.get(state,:pid)
        receiver = Map.get(state,:node)
        count = Map.get(state,:c)
        neighbour_list = Map.get(state,:neighbour_list)
        if length(neighbour_list)==0 do
            time = System.system_time(:millisecond)-start_time
            IO.puts "Total time of Convergence #{time}"
            Process.exit(pid,:kill)
        end
        nextNode = Enum.random(neighbour_list)
        #IO.puts "Receiver  #{receiver}  Count #{count}"
        if count < 3 do
            rs = Map.get(state,:s)
            rw = Map.get(state,:weight)
            new_s = rs+sender_s
            new_w = rw+sender_w
            ratio = rs/rw
            new_ratio = new_s/new_w
            #IO.puts "Node   #{receiver}    #{rs}    #{rw}   #{count}      #{ratio-new_ratio}"
            #:timer.sleep(100)
            count  = if abs(ratio-new_ratio) < :math.pow(10,-10) do
                        count+1
                    else
                        count
                    end
            state = Map.put(state,:s,new_s/2)
            state = Map.put(state,:weight,new_w/2)
            state = Map.put(state,:c,count)
            GenServer.cast(nextNode,{:transmitpush,[new_s/2,new_w/2,receiver],start_time,parentid})
            {:noreply,state}
        else
            update_neighbours(neighbour_list,pid)
            GenServer.cast(nextNode,{:transmitpush,[sender_s/2,sender_w/2,sender],start_time,parentid})
            #:timer.sleep(100)
            time = System.system_time(:millisecond)-start_time
            IO.puts "Node #{receiver} converged at time #{time}"

            send(parentid, {:from_child, self()})
            {:noreply,state}
        end
    end
end
