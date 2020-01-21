defmodule MyProgram do
  use Supervisor
  def main(argv) do
#    IO.inspect (argv)

      options = [strict: [key: :string]]
      {_, ar2, _} = OptionParser.parse(argv,options)

     num_nodes = String.to_integer(List.first(ar2))
      topology  = Enum.at(ar2,1)
      algorithm = List.last(ar2)

      #mix escript.build
      #escript my_program 1000 topology algorithm

      num_nodes = ceil(num_nodes/100)*100
      #{:ok,pid} = Supervi1.start_link(num_nodes)
      case topology do
        "line" ->Supervi1.line(algorithm,num_nodes,self())
        "full"-> Supervi1.full(algorithm,num_nodes,self())
        "honeycomb"-> Supervi1.honeycomb(algorithm,num_nodes,self())
        "randomhoneycomb"-> Supervi1.randomhoneycomb(algorithm,num_nodes,self())
        "random2d"-> Supervi1.random2d(algorithm,num_nodes,self())
        "threedtorus"-> Supervi1.threedtorus(algorithm,num_nodes,self())
      end
      listen_gossip(0,num_nodes,System.monotonic_time(:microsecond))
  end

  def listen_gossip(count, num_check, start_time) do
    # IO.puts("****in listen***")
    if count > num_check do
      IO.puts"exit"
    else
      receive do
        {:from_child} ->  IO.puts("received node to exit------#{count}")
        listen_gossip(count + 1, num_check, start_time)

      end
    end

end
end
