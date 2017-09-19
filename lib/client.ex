defmodule Project2.Client do
    use GenServer
    
    def start_link(args) do
        GenServer.start_link(__MODULE__,:ok)
        Project2.Exdistutils.start_distributed(Integer.to_string(args)|>String.to_atom)
        IO.inspect Node.self()
        Node.ping :"project2@10.228.7.203"
        #loop()
    end

    def init(:ok) do
        {:ok,%{}}
    end
    
    def loop do
        Process.sleep(1_000_000)
    end
end