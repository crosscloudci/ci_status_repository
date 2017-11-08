defmodule CncfDashboardApi.DashboardChannel do
  use CncfDashboardApi.Web, :channel


  def join("dashboard:*", payload, socket) do
    if authorized?(payload) do
      dashboard = ~s({
        "dashboard": {
          "clouds":[
            {
              "cloud_id":1,
              "name":"cloud 1"
            },
            {
              "cloud_id":2,
              "name":"cloud 2"
            }
          ],
          "projects":[
            {
              "project_id":1,
              "title":"Kubernetes", 
              "caption":"Orchestration",
              "url":"http://kubernetes.io/",
              "icon":"https://www.cncf.io/wp-content/uploads/2016/09/ico_kubernetes-100x100.png",
              "deployments": ["AWS", "Azure", "Bluemix", "GCE", "GKE", "Packet"],
              "pipelines":[
                {
                  "pipeline_id":1,
                  "project_id":1,
                  "status":"successful",
                  "stable_tag":"release",
                  "head_commit":"2342342342343243sdfsdfsdfs",
                  "jobs":[
                    {
                      "pipeline_id":1,
                      "project_id":1,
                      "job_id":23,
                      "cloud_id":1,
                      "status":"fail"
                    },
                    {
                      "pipeline_id":1,
                      "project_id":1,
                      "job_id":24,
                      "cloud_id":2,
                      "status":"success"
                    }
                  ]
                },
                {
                  "pipeline_id":2,
                  "project_id":1,
                  "status":"successful",
                  "stable_tag":"release",
                  "head_commit":"2342342342343243sdfsdfsdfs",
                  "jobs":[
                    {
                      "pipeline_id":2,
                      "project_id":1,
                      "job_id":23,
                      "cloud_id":1,
                      "status":"fail"
                    }
                  ]
                }
              ]
            },
            {
              "project_id":2,
              "title":"Prometheus",
              "caption":"Monitoring",
              "url":"http://prometheus.io/", 
              "icon":"https://www.cncf.io/wp-content/uploads/2016/09/ico_prometheus-100x100.png", 
              "deployments": ["AWS", "Azure", "Bluemix", "GCE", "GKE", "Packet"],
              "pipelines":[
                {
                  "pipeline_id":1,
                  "project_id":1,
                  "status":"successful",
                  "stable_tag":"release",
                  "head_commit":"2342342342343243sdfsdfsdfs",
                  "jobs":[
                    {
                      "pipeline_id":1,
                      "project_id":1,
                      "job_id":23,
                      "cloud_id":1,
                      "status":"fail"
                    },
                    {
                      "pipeline_id":1,
                      "project_id":1,
                      "job_id":24,
                      "cloud_id":2,
                      "status":"success"
                    }
                  ]
                },
                {
                  "pipeline_id":2,
                  "project_id":1,
                  "status":"successful",
                  "stable_tag":"release",
                  "head_commit":"2342342342343243sdfsdfsdfs",
                  "jobs":[
                    {
                      "pipeline_id":2,
                      "project_id":1,
                      "job_id":23,
                      "cloud_id":1,
                      "status":"fail"
                    }
                  ]
                }
              ]
            },
            {
              "project_id":3,
              "title":"OpenTracing", 
              "caption":"Distributed Tracing API", 
              "url":"http://opentracing.io/", 
              "icon":"https://www.cncf.io/wp-content/uploads/2016/09/logo_opentracing.png", 
              "deployments": ["AWS", "Azure", "Bluemix", "GCE", "GKE", "Packet"],
              "pipelines":[
                {
                  "pipeline_id":1,
                  "project_id":2,
                  "status":"successful",
                  "stable_tag":"release",
                  "head_commit":"2342342342343243sdfsdfsdfs",
                  "jobs":[
                    {
                      "pipeline_id":1,
                      "project_id":2,
                      "job_id":26,
                      "cloud_id":1,
                      "status":"fail"
                    },
                    {
                      "pipeline_id":1,
                      "project_id":2,
                      "job_id":27,
                      "cloud_id":2,
                      "status":"success"
                    }
                  ]
                },
                {
                  "pipeline_id":2,
                  "project_id":2,
                  "status":"successful",
                  "stable_tag":"release",
                  "head_commit":"2342342342343243sdfsdfsdfs",
                  "jobs":[
                    {
                      "pipeline_id":2,
                      "project_id":2,
                      "job_id":29,
                      "cloud_id":1,
                      "status":"fail"
                    }
                  ]
                }
              ]
            },
            {
              "project_id":4,
              "title":"Fluentd", 
              "caption":"Logging", 
              "url":"http://fluentd.org/", 
              "icon":"https://www.cncf.io/wp-content/uploads/2016/09/logo_fluentd.png", 
              "deployments": ["AWS", "Azure", "Bluemix", "GCE", "GKE", "Packet"],
              "pipelines":[
                {
                  "pipeline_id":1,
                  "project_id":2,
                  "status":"successful",
                  "stable_tag":"release",
                  "head_commit":"2342342342343243sdfsdfsdfs",
                  "jobs":[
                    {
                      "pipeline_id":1,
                      "project_id":2,
                      "job_id":26,
                      "cloud_id":1,
                      "status":"fail"
                    },
                    {
                      "pipeline_id":1,
                      "project_id":2,
                      "job_id":27,
                      "cloud_id":2,
                      "status":"success"
                    }
                  ]
                },
                {
                  "pipeline_id":2,
                  "project_id":2,
                  "status":"successful",
                  "stable_tag":"release",
                  "head_commit":"2342342342343243sdfsdfsdfs",
                  "jobs":[
                    {
                      "pipeline_id":2,
                      "project_id":2,
                      "job_id":29,
                      "cloud_id":1,
                      "status":"fail"
                    }
                  ]
                }
              ]
            },
            {
              "project_id":5,
              "title":"linkerd", 
              "caption":"Service Mesh", 
              "url":"https://www.linkerd.io/", 
              "icon":"https://www.cncf.io/wp-content/uploads/2016/09/ico_linkerd5-e1485379975148.png", 
              "deployments": ["AWS", "Azure", "Bluemix", "GCE", "GKE", "Packet"],
              "pipelines":[
                {
                  "pipeline_id":1,
                  "project_id":2,
                  "status":"successful",
                  "stable_tag":"release",
                  "head_commit":"2342342342343243sdfsdfsdfs",
                  "jobs":[
                    {
                      "pipeline_id":1,
                      "project_id":2,
                      "job_id":26,
                      "cloud_id":1,
                      "status":"fail"
                    },
                    {
                      "pipeline_id":1,
                      "project_id":2,
                      "job_id":27,
                      "cloud_id":2,
                      "status":"success"
                    }
                  ]
                },
                {
                  "pipeline_id":2,
                  "project_id":2,
                  "status":"successful",
                  "stable_tag":"release",
                  "head_commit":"2342342342343243sdfsdfsdfs",
                  "jobs":[
                    {
                      "pipeline_id":2,
                      "project_id":2,
                      "job_id":29,
                      "cloud_id":1,
                      "status":"fail"
                    }
                  ]
                }
              ]
            },
            {
              "project_id":6,
              "title":"gRPC", 
              "caption":"Remote Procedure Call", 
              "url":"http://www.grpc.io/", 
              "icon":"https://www.cncf.io/wp-content/uploads/2016/09/logo_grpc-1-e1488466098164.png", 
              "deployments": ["AWS", "Azure", "Bluemix", "GCE", "GKE", "Packet"],
              "pipelines":[
                {
                  "pipeline_id":1,
                  "project_id":2,
                  "status":"successful",
                  "stable_tag":"release",
                  "head_commit":"2342342342343243sdfsdfsdfs",
                  "jobs":[
                    {
                      "pipeline_id":1,
                      "project_id":2,
                      "job_id":26,
                      "cloud_id":1,
                      "status":"fail"
                    },
                    {
                      "pipeline_id":1,
                      "project_id":2,
                      "job_id":27,
                      "cloud_id":2,
                      "status":"success"
                    }
                  ]
                },
                {
                  "pipeline_id":2,
                  "project_id":2,
                  "status":"successful",
                  "stable_tag":"release",
                  "head_commit":"2342342342343243sdfsdfsdfs",
                  "jobs":[
                    {
                      "pipeline_id":2,
                      "project_id":2,
                      "job_id":29,
                      "cloud_id":1,
                      "status":"fail"
                    }
                  ]
                }
              ]
            }
          ]
        }
      })


      dashboard_json = Poison.decode!(dashboard)
      response = CncfDashboardApi.DashboardView.render("dashboard.json", %{dashboard: dashboard_json})
      {:ok, %{reply: response}, socket}
    else
    {:error, %{reason: "unauthorized"}}
    end
  end

  def join(topic, _resource, socket) do
    # if permitted_topic?(socket, :listen, topic) do
      { :ok, %{ message: "Joined" }, socket }
    # else
    #   { :error, :authentication_required }
    # end
  end

  # def join(_room, _payload, _socket) do
  #   { :error, :authentication_required }
  # end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (dashboard:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
