defmodule CncfDashboardApi.DashboardControllerTest do
  use CncfDashboardApi.ConnCase

  alias CncfDashboardApi.Dashboard
  @valid_attrs %{ref: "some content", status: "some content"}
  @invalid_attrs %{}

  def test_dashboard do
    fixture_dashboard = ~s({
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
    dashboard = Poison.decode!(fixture_dashboard)
    cloud_list = CncfDashboardApi.Repo.all(from cd1 in CncfDashboardApi.Clouds, select: %{"cloud_id" => cd1.id, "name" => cd1.cloud_name}) 

    %{"dashboard" => %{"clouds" => _, "projects" => p1}} = dashboard 

    with_cloud = %{"dashboard" => %{"clouds" => cloud_list, "projects" => p1}} 
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    {:ok, upsert_count, cloud_map} = CncfDashboardApi.GitlabMigrations.upsert_clouds()
    conn = get conn, dashboard_path(conn, :index)
    # cloud_list = json_response(conn, 200)["dashboard"]["clouds"] |> List.first
    dashboard = json_response(conn, 200)
    assert  dashboard == test_dashboard 
  end

end
