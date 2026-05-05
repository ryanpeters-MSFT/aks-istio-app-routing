# AKS Istio App Routing Gateway API

This repository contains a minimal sample for testing AKS App Routing with the Gateway API and Istio integration in preview.

The sample does the following:

- Registers the required AKS preview features.
- Creates an AKS cluster with Gateway API and App Routing Istio enabled.
- Deploys the Istio `httpbin` sample workload.
- Creates a Gateway and HTTPRoute.
- Sends a test request through the gateway public IP.

## Files

- `setup.ps1` provisions Azure resources and applies the sample manifests.
- `gateway.yaml` defines the Gateway using the `approuting-istio` gateway class.
- `httproute.yaml` defines the HTTPRoute for the `httpbin` service.

## Deploy

From the repository root, run:

```powershell
.\setup.ps1
```

The script uses these defaults:

- Resource group: `rg-istio-approuting-gateway`
- Cluster name: `aksistioapprouting`
- Location: `eastus2`

Edit `setup.ps1` if you want to change those values.

## Routing Behavior

This sample currently uses host-based routing.

The HTTPRoute in `httproute.yaml` matches:

- Host: `httpbin.example.com`
- Path prefix: `/get`

Because of that, the validation request sent by `setup.ps1` includes this header:

```text
Host: httpbin.example.com
```

If you test manually, use the gateway IP returned by the script together with that host header. Example:

```powershell
curl -H "Host: httpbin.example.com" http://<gateway-ip>/get
```

## Verify

To inspect the deployed resources:

```powershell
kubectl get gateway
kubectl get httproute
kubectl get svc httpbin
kubectl get pods
```

To retrieve the gateway address again:

```powershell
kubectl get gateways.gateway.networking.k8s.io httpbin-gateway -o jsonpath='{.status.addresses[0].value}'
```

## References

- AKS blog: https://blog.aks.azure.com/2026/03/18/app-routing-gateway-api
- Microsoft Learn: https://learn.microsoft.com/azure/aks/app-routing-gateway-api