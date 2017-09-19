defmodule Project2 do
  use GenServer
  def start_link do
    GenServer.start_link(__MODULE__,:ok,name: :Server)
  end
  def init(:ok) do
    {:ok,%{}}
  end

  def main(args\\[]) do
    number_of_node=elem(List.to_tuple(args),0)
    Project2.Exdistutils.start_distributed(:project2)
    start_link() #this is where the server genserver starts
    IO.puts "Building Nodes"
    spawnner(number_of_node)
    #loop()
  end

  def spawnner(number_of_node,temp\\0) do
    IO.puts(temp)
    case String.to_integer(number_of_node)>temp do
      true->Process.spawn((fn->Project2.Client.start_link(Integer.to_string(temp)|>String.to_atom) end),[])
            spawnner(number_of_node,temp+1)
             {:ok}
      false->{:ok}
  end
  end

  def loop do
    loop
  end
end
