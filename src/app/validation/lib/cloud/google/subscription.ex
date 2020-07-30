defmodule Cloud.Google.Subscription do
  @moduledoc "Wrapper for interacting with GoogleCloud pub sub subscriptions."

  alias GoogleApi.PubSub.V1, as: PubSub
  alias PubSub.Model.AcknowledgeRequest
  alias PubSub.Model.ExpirationPolicy
  alias PubSub.Model.PullRequest
  alias PubSub.Model.PullResponse
  alias PubSub.Model.Subscription

  import Util
  import PubSub.Api.Projects
  require Logger

  @type t :: Subscription.t()

  @spec short_name(t) :: String.t()
  def short_name(subscription) do
    subscription.name |> String.split("/") |> List.last()
  end

  @spec get(Cloud.Google.pubsub_conn(), String.t()) :: t | nil
  def get(conn, name) do
    pubsub_projects_subscriptions_get(conn, Coda.project_id(), name)
    |> ok_or_nil()
  end

  @spec create(Cloud.Google.pubsub_conn(), String.t(), Cloud.Google.Topic.t()) :: t
  def create(conn, name, topic) do
    case get(conn, name) do
      nil ->
        subscription_body = %Subscription{
          topic: topic.name,
          messageRetentionDuration: "3600s",
          # 1 day
          expirationPolicy: %ExpirationPolicy{ttl: "86400s"}
        }

        pubsub_projects_subscriptions_create(conn, Coda.project_id(), name,
          body: subscription_body
        )
        |> ok_or_error(Cloud.Google.ApiError, "failed to create subscription")

      subscription ->
        subscription
    end
  end

  @spec pull_raw(Cloud.Google.pubsub_conn(), t) :: PullResponse.t()
  def pull_raw(conn, subscription) do
    pull_request = %PullRequest{maxMessages: 20}

    Logger.info("pulling subscription #{short_name(subscription)}")

    pubsub_projects_subscriptions_pull(
      conn,
      Coda.project_id(),
      short_name(subscription),
      body: pull_request
    )
    |> ok_or_error(Cloud.Google.ApiError, "failed to pull subscription")
  end

  @spec acknowledge(Cloud.Google.pubsub_conn(), t, PullResponse.t() | [String.t()]) :: any
  def acknowledge(conn, subscription, %PullResponse{receivedMessages: messages}) do
    acknowledge(conn, subscription, Enum.map(messages, & &1.ackId))
  end

  def acknowledge(conn, subscription, ack_ids) when is_list(ack_ids) do
    ack_request = %AcknowledgeRequest{ackIds: ack_ids}

    pubsub_projects_subscriptions_acknowledge(
      conn,
      Coda.project_id(),
      short_name(subscription),
      body: ack_request
    )
    |> ok_or_error(Cloud.Google.ApiError, "failed to acknowledge subscription messages")
  end

  # TODO: allow this to send intermediate acknowledgements and handle failures in f?
  @spec pull_and_process(Cloud.Google.pubsub_conn(), t, function) :: no_return
  def pull_and_process(conn, subscription, f) do
    response = pull_raw(conn, subscription)

    if response.receivedMessages != nil do
      count = length(response.receivedMessages)
      Logger.info("beginning to process #{count} messages")

      ack_ids =
        Enum.map(response.receivedMessages, fn received_message ->
          message_data =
            received_message.message.data
            |> Base.decode64!()
            |> Jason.decode!()

          f.(message_data)
          received_message.ackId
        end)

      acknowledge(conn, subscription, ack_ids)
      Logger.info("processed and acknowledged #{count} messages")
    else
      Logger.info("no messages received: #{inspect(response)}")
      Logger.info("USING DUMMY MESSAGE")
      message_data =
	%{
	  "insertId" => "0qzofjohw1pxwk86l",
	  "jsonPayload" => %{
	    "event_id" => "64e2d3e86c37c09b15efdaf7470ce879",
	    "level" => "Trace",
	    "message" => "Successfully produced a new block",
	    "metadata" => %{
	      "breadcrumb" => %{
		"just_emitted_a_proof" => false,
		"staged_ledger" => "<opaque>",
		"validated_transition" => %{
		  "data" => %{
		    "current_protocol_version" => "0.1.0",
		    "delta_transition_chain_proof" => "<opaque>",
		    "proposed_protocol_version" => "<None>",
		    "protocol_state" => %{
		      "body" => %{
			"blockchain_state" => %{
			  "snarked_ledger_hash" => "rTmxdbpCYyCer8SPRsmEhmaugkdMrYZJ9FpNZqoT9xbAkCca86NPpJycDsWxH7X1N4fgCro9XEo1JJSjSsenYQupHWiv1GqiKS63pnctSpNzmijMAJ5en43WQatiSgjiBefadSXmQbKnHGsz5AV1ho4JDFZ7YcPuDtXkBhFchZ2qCo9DrXYuhgF52KXwwkLZajSWHWGn66Qep3sJG7GV8DDuZtkZohMYecjEvpNqQhd47hiLgL4Fn17qPEjpd4H7ocA82FfXkqpzW5anYagZnsQYMYWiJpf1bgQYpB8EhXzqCNQRjS5dSyJUV7GYd7jV",
			  "snarked_next_available_token" => "2",
			  "staged_ledger_hash" => %{
			    "non_snark" => %{
			      "aux_hash" => "UqLxvYR9g9uCpzagVcupNRsxyuqy6UBwVbzGxCu8zxdUfowYJa",
			      "ledger_hash" => "4mKBT3x7nzrhid1Tev2RM3RhZdUj61BZrgKy2HGDDkbPz9wXpRuUmWfLwg9c5yFfbmGw9CTvTwMc3uhGxbupJWy3LSQkYCzw5yAjVuM6LKLr3ZtCkA7gLthC1w4e2hc7o3k7nwcYkiS4rCGeoD95MCHNC6qEuEBLDPnaunw6EA7ifdQQqjY6MdMCnaxxqTqmBNM4kA5gx3SQapP7mLnLLqc9MsoCjyig7rYSjmB6JBXyvCZtDcjtiCorMEtpSpNF7mGcm4XxVBGnPggWtMTDhCXsyJsgwUY4JHWswxJL4wWueS9tHWjcBLBM9VC7A7nRFz",
			      "pending_coinbase_aux" => "Y2AnrmUrzS5qMmAjv27sBnqUr8oin9h2dJBqoEXPK2oUsZ3obk"
			    },
			    "pending_coinbase_hash" => "A2UdxEssKUgJEtRppwuLCYM89c66A9PKCLv64MCDWpBugPrrwAogeLtmYs4An1wh9eJaioM9o9gPdFt7cLZv86AS7CcKdfUxr45rgckNnsXLKXE8kMxFv5kJ9wwRtt21hvzhYaJAUm3hchCuDCCJvmzD5KJkAp8vxD9dj7b1PVdCKzK7UYWQU9eoXrUfRcVfPR2XSEGR45k4triptk7K2YcKGpZtiL2VMzZDiwK6jRaSz9nYt5dJ7PnmAq5zdnpHQyn7mFUBfAsVUHSnFbjzWgqfQ9HjC5Hhh4ZDQs1wRXw9JVgGNFowbf4gu9d16896rV"
			  },
			  "timestamp" => "1596061432000"
			},
			"consensus_state" => %{
			  "blockchain_length" => "444",
			  "curr_global_slot" => %{
			    "slot_number" => "950",
			    "slots_per_epoch" => "480"
			  },
			  "epoch_count" => "1",
			  "has_ancestor_in_same_checkpoint_window" => true,
			  "last_vrf_output" => "<opaque>",
			  "min_window_density" => "160",
			  "next_epoch_data" => %{
			    "epoch_length" => "234",
			    "ledger" => %{
			      "hash" => "rTmxdbpCYyCer8SPRsmEhmaugkdMrYZJ9FpNZqoT9xbAkCca86NPpJycDsWxH7X1N4fgCro9XEo1JJSjSsenYQupHWiv1GqiKS63pnctSpNzmijMAJ5en43WQatiSgjiBefadSXmQbKnHGsz5AV1ho4JDFZ7YcPuDtXkBhFchZ2qCo9DrXYuhgF52KXwwkLZajSWHWGn66Qep3sJG7GV8DDuZtkZohMYecjEvpNqQhd47hiLgL4Fn17qPEjpd4H7ocA82FfXkqpzW5anYagZnsQYMYWiJpf1bgQYpB8EhXzqCNQRjS5dSyJUV7GYd7jV",
			      "total_currency" => "116305100000054946"
			    },
			    "lock_checkpoint" => "2qeUwbiMJmqg8ofgg6i49gzA45RbZKRuLb7WfgFvRSZgxgsMD5fQJYombXbDw199b2EMA4W4CvFTBwEzMYHpMvDBPZMww836t3tbRBuujsVGeHhFpGAdsuJ2WYPNjsZauV2zbebEWgkywfF2hiGBdhnLm9qSxn5P3pgJxsQDWFz5N3VQD2hjK7DUrBwacCbkYBdFSBxK47NqWLHgCxw3xP3ZLET5kXpmbNovhik3VRRcrJ7XGvZcmuzXBta9Vekby6xEDFQphNm8DsJRMZw2SMEdZWLCgBba9tyymCiBhTKYYpUWwF1aToSAHJZuT",
			    "seed" => "3DUfsm6EoHif4oppZTezVBuXPwNwdCcWtGcvRtWZPFpoTwPXMzSLScJCaMWK3Jiv9EaXZyCR3t1BpTSvWoB9BjMTV51NpKJKZiZ86xL5QKdUbqMwUwYwqPe3aHHvNpCcU3obqTETyB1f7F4W53qK4fPbcUv1Emf6fcD834rPgup4MCQb1g36VnS3b6kdr81NdfGBTPBLYe47tmt8DT582mYYfN1Qv2Tfju6goFzFik6meKqBbaiaEtE8Yh7ASYywhQnUuRejBEYBdAJaCA9CDSfLFDJ1KDj8UyBu5GmGNEBAnUWD1xoJSojyJhcazHE3y",
			    "start_checkpoint" => "D2rcXVQa8dyAN24rbk2DBL6e9sPTDVCVzvQJC3ikTmCvraVUSbJ2zUqnS5xmrtuq8pEAEfKv6nUzQMvC9appv1qV6h9CKqTdAnDJyrUCC89CXYXpY1o9XoRyTRsRhGXVik1UnGXH8PU5yA6zGfGDQSeg9dhWsRcDqDa4k92pNPx8stNzUm6PhjNrAAGiz4aGEyekZDvsp2uceCZum9F8o2RqZ8nQnExgyZbcxBkxHhVrGtWrZcWQsMQhsp7fjzKR1i1VmWtYQJHeHgFwZLYTQFpMqWpVDKfeiwap3tE8ycDSC4JsBfxokCkiZKNiLqWiK9"
			  },
			  "staking_epoch_data" => %{
			    "epoch_length" => "211",
			    "ledger" => %{
			      "hash" => "rTmxdbpCYyCer8SPRsmEhmaugkdMrYZJ9FpNZqoT9xbAkCca86NPpJycDsWxH7X1N4fgCro9XEo1JJSjSsenYQupHWiv1GqiKS63pnctSpNzmijMAJ5en43WQatiSgjiBefadSXmQbKnHGsz5AV1ho4JDFZ7YcPuDtXkBhFchZ2qCo9DrXYuhgF52KXwwkLZajSWHWGn66Qep3sJG7GV8DDuZtkZohMYecjEvpNqQhd47hiLgL4Fn17qPEjpd4H7ocA82FfXkqpzW5anYagZnsQYMYWiJpf1bgQYpB8EhXzqCNQRjS5dSyJUV7GYd7jV",
			      "total_currency" => "116305100000054946"
			    },
			    "lock_checkpoint" => "D2rcXVQYbjVwVKAyGV2fPTwfD9EPqUcAyGqiX8kGSRkaaHrjVmWvmBkTXihNBWRF5dd71QZVuRfcyLdJ4zRbvTw9h8mPj7xRy2CnhGQyLzHjgQUMdNPsZ5k8gntXaiRU7eQKDqN1yXoA7AyaibdGVPtfvQMCa1PHnVCGtiQea38G7YPn214Zg8WNKjM1heuALH3sEfMxrTNZDv3bM8Zk1fEJLJQgAq7oaWoPkWGMYwS7NXhAjqViyQyYB1Dmj91nNFfebpuXWKkQbFcU8xH5nZV2AKB4oRckMx2PQrodDcNSg2htCXdH5kn3pDGyC14z2r",
			    "seed" => "3DUfsm6Fq6kQdBUqXgfd64TxC8t2WmTfQm9ykbQM7zqU5JWijVM86gCHatmNeRsfS2QxKH6iBo21eN4jzVS4voFy3y4g7E8vKBgs4AfmGUtHXXmNtRdLE2xUeztRpTQ2XxQY1By9ZwBDjdLBZKxsxUT78c5JuN7JDxgjwaBE87J8ceqNCs8R8SyninRpqss5oQJKpx8c4pHynpKukAuKPH1i8sAdBLj9M6PX9HSfLeW4LgHdfcZ9VnVaj49dFdTDr1uw8XjkrhLw6N4PYDHZVh1QoTmnFU6EqnZnBq9P34Ss2nLzmfYEo8w3gGS4m6w1i",
			    "start_checkpoint" => "3gFyJAMHS7m"
			  },
			  "sub_window_densities" => ["0", "20", "20", "20", "20", "20",
						     "20", "20"],
			  "total_currency" => "116305100.000054946"
			},
			"constants" => %{
			  "delta" => "3",
			  "genesis_state_timestamp" => "1595890432000",
			  "k" => "20"
			},
			"genesis_state_hash" => "3j7Fqw9fZATRmoc7TH4UqqYXJSwYJGxzvehuznWBzbJMx5eb96X1Ewybs6LkTxeW6J3yVBAFF6H3ofbNvyojxbWMo7nZrTvYVaVEMkrnYcor1Pfx3TatiFLNS1UtE7ai4GU8f3UC3UfkZE2r38JMzz7owHurmisq1jnV7EXUuJ6DWW9iCpPYqmvhkWUWWJseJMS4xCQayoAVztdKoPmFRvXA7KGre5CQpVyXMuUEb73yyCLuFQwc1jxUBozhMAbbeXwi6YD8XgcwvPEkFukoDv9dPQiavFCJ1FGP458ktaY8xAZTycnichHML7ab6mhrb"
		      },
		      "previous_state_hash" => "D2rcXVQbeBZWiA2euz62fZ7G8Ujf1yLYd4tmUh1CkfAx2HCUWWJ4wdWwrvod1mqQUecJbUj7cQtXcPEehzGf2svn3Yf8MD5fskAevSYhhsTdL8L7n8W5XCcDGEQDC4yspPTkiBcP1sWQPRjaAKX47811iHW43HAh2qG89chpuBMFZfwL3ezSKg8JadGnXh1yutGggx6Ts59kAbg8zK2AJtsFf6QJfinQL16fiAabZLXb8yHUuFBusnUCjhcQUsQnihN7LFvFc9VMqLWxaa4t5cuy6cZhvMUuCziVWXHBduXbUcBG4f9rfJMRdkKqK6zkFT"
		    },
		    "protocol_state_proof" => "<opaque>",
		    "staged_ledger_diff" => "<opaque>"
		  },
		  "hash" => "D2rcXVQbdAXSPeerqyMQxfMz5WWWSy7a1JSRJ8Y1WDEfTN1u4o7PJMDzwBQf5wK84U1LELcM3S6CQpnWyTFCgn2o5UZsFQQmpkEFgGCrNnESXCsbhczr293WmPJMizhjc81wkKWHL3yXZ9dtodhBkPSgPbD3fAwLKvQKdEEoyBemRGtz8fRXQGCmmXXywgxF4J8WQDhLVBE3DcEc5b1UpGoYSJuWV2Rv5eFwPoTMCgoS9wUvtevFxTXTUtj5cx43EgXZnZ8UqWeYCVcZqSRMP9N4WGh92Dckq6Pje1oz4Qxs1FM2dWcmparV8grEC6AH6Y"
		}
	      },
	      "host" => "34.74.175.158",
	      "peer_id" => "12D3KooWNZHvHvkYUAkzHqcLhvTAHznwP692nVJmnFCGzcq7fuGS",
	      "pid" => 10,
	      "port" => 10010
	    },
	    "source" => %{
	      "location" => "File \"src/lib/block_producer/block_producer.ml\", line 535, characters 44-51",
	      "module" => "Block_producer"
	    },
	    "timestamp" => "2020-07-29 22:26:16.920046Z"
	  },
	  "labels" => %{
	    "k8s-pod/app" => "whale-block-producer-5",
	    "k8s-pod/class" => "whale",
	    "k8s-pod/pod-template-hash" => "7f8ff7dc4c",
	    "k8s-pod/role" => "block-producer",
	    "k8s-pod/testnet" => "regeneration",
	    "k8s-pod/version" => "0.0.12-beta-rosetta-dockerfile-aec5631"
	  },
	  "logName" => "projects/o1labs-192920/logs/stdout",
	  "receiveTimestamp" => "2020-07-29T22:26:19.546955093Z",
	  "resource" => %{
	    "labels" => %{
	      "cluster_name" => "coda-infra-east",
	      "container_name" => "coda",
	      "location" => "us-east1",
	      "namespace_name" => "regeneration",
	      "pod_name" => "whale-block-producer-5-7f8ff7dc4c-csbf5",
	      "project_id" => "o1labs-192920"
	    },
	    "type" => "k8s_container"
	  },
	  "severity" => "INFO",
	  "timestamp" => "2020-07-29T22:26:17.862113146Z"
	}
      f.(message_data)
    end
  end
end
