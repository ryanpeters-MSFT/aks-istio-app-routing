# aks app routing gateway api (preview) sample
# ref: https://blog.aks.azure.com/2026/03/18/app-routing-gateway-api
# ref: https://learn.microsoft.com/azure/aks/app-routing-gateway-api

$group   = "rg-istio-approuting-gateway"
$cluster = "aksistioapprouting"
$location = "eastus2"

# install/update aks-preview extension (min version 19.0.0b26)
az extension add -n aks-preview
az extension update -n aks-preview

# register required preview feature flags
az feature register --namespace "Microsoft.ContainerService" -n "ManagedGatewayAPIPreview"
az feature register --namespace "Microsoft.ContainerService" -n "AppRoutingIstioGatewayAPIPreview"

# wait for both features to show Registered before continuing
az feature show --namespace "Microsoft.ContainerService" -n "ManagedGatewayAPIPreview" --query "properties.state" -o tsv
az feature show --namespace "Microsoft.ContainerService" -n "AppRoutingIstioGatewayAPIPreview" --query "properties.state" -o tsv

# propagate registration to the provider
az provider register -n Microsoft.ContainerService

# create resource group and cluster with managed gateway api + app routing istio
az group create -n $group -l $location
az aks create -g $group -n $cluster -l $location --enable-gateway-api --enable-app-routing-istio

# merge credentials into local kubeconfig
az aks get-credentials -g $group -n $cluster

# verify istiod is running in aks-istio-system
kubectl get pods -n aks-istio-system

# deploy the httpbin sample app
$istioRelease = "release-1.27"
kubectl apply -f "https://raw.githubusercontent.com/istio/istio/$istioRelease/samples/httpbin/httpbin.yaml"

# create gateway (approuting-istio class) and httproute
kubectl apply -f .\gateway.yaml
kubectl apply -f .\httproute.yaml

# wait for gateway to be programmed and retrieve its external ip
kubectl wait --for=condition=programmed gateways.gateway.networking.k8s.io httpbin-gateway --timeout=120s
$ingressHost = kubectl get gateways.gateway.networking.k8s.io httpbin-gateway -o jsonpath='{.status.addresses[0].value}'

# send a test request — expect HTTP 200
curl -s -I -H "Host: httpbin.example.com" "http://$ingressHost/get"