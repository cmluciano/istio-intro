#!/bin/bash

set -e 

FORTIO_POD=$(kubectl get pods | grep fortio | awk '{ print $1 }')

echo "We start with the basic v1 routerule for the httpbin service and the circuit-breaker"
read -n 1 -s -r -p "Press any key to continue"
kubectl apply -f ../scripts/samples/bookinfo/kube/route-rule-all-v1.yaml
kubectl apply -f ../scripts/samples/bookinfo/kube/destinationpolicies/bookinfo-circuit-breaker.yaml
cat ../scripts/samples/bookinfo/kube/destinationpolicies/bookinfo-circuit-breaker.yaml

echo "Our first load test will be with one call to ensure that we return a 200."
read -n 1 -s -r -p "Press any key to continue"
kubectl exec -it $FORTIO_POD --container fortio -- /usr/local/bin/fortio load -curl  http://reviews:9080/get

echo "Now we can trip the circuit breaker with 2 connections and 20 requests. Recall that our settings only allow for 1 connection and 1 request"
read -n 1 -s -r -p "Press any key to continue"
kubectl exec -it $FORTIO_POD --container fortio -- /usr/local/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://reviews:9080/get

echo "We now increase our load to 3 connections with 20 requests. These should cause even more 503s"
read -n 1 -s -r -p "Press any key to continue"
kubectl exec -it $FORTIO_POD --container fortio -- /usr/local/bin/fortio load -c 3 -qps 0 -n 20 -loglevel Warning http://reviews:9080/get

echo "Ready to cleanup circuit-breaker"
read -n 1 -s -r -p "Press any key to continue"
kubectl delete -f ../scripts/samples/bookinfo/kube/route-rule-all-v1.yaml
kubectl delete -f ../scripts/samples/bookinfo/kube/destinationpolicies/bookinfo-circuit-breaker.yaml

