# External Service Template - Documentation

## Values

- cpu - The number of cores requested for each replica.
- fqdn - The fully qualified domain name by which the application can be accessed.
- healthEndpoint - The route to healthcheck endpoint.
- image - The image specification including tag of the container image to use.
- memory - The amount of memory requested for each replica.
- port - The port on the container where the app can be accessed
- replicas - The number of replicas to create in the replica set.

## Template Example

In the example below, a single target is referenced called `development` with a clusters value of 1.  The values section contains values for the properties listed above.

```yaml
deployments:
  default:
    target: development
    clusters: 1
    values:
      cpu: 1
      fqdn: example.io
      healthEndpoint: /healthcheck
      image: ghcr.io/acompany/sampleapp:latest
      memory: 1G
      port: 5000
      replicas: 3
```
