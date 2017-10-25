require IEx;
defmodule CncfDashboardApi.YmlReader.GitlabCiTest do
  use ExUnit.Case

  test "get" do 
    yml = CncfDashboardApi.YmlReader.GitlabCi.get()
    assert yml |> is_binary  
  end
  test "cloud_list" do 
    cloud_list = CncfDashboardApi.YmlReader.GitlabCi.cloud_list()
    assert Enum.find_value(cloud_list, fn(x) -> x["cloud_name"] == "aws" end) 
  end
end
