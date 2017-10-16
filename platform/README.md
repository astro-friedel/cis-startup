# Crops in Silico Platform API / UI / IDE
See https://github.com/cropsinsilico

# Build
```bash
git clone https://github.com/cropsinsilico/cis-ui && cd cis-ui
docker build -t bodom0015/cis-ui .
```

# Run
First and foremost, create a `basic-auth` secret by substituting your desired username/password and running:
```bash
kubectl create secret generic basic-auth \                                # kubectl create args
    --from-literal=auth="$(docker run -it --rm bodom0015/htpasswd \       # docker run args
        -b -c /dev/stdout DESIRED_USERNAME DESIRED_PASSWORD | tail -1)"   # htpasswd args
```

Next, create the ingress rules:
```bash
kubectl create -f ingress.yaml
```

This will set up the routes for your application.

NOTE: This must be done before starting the loadbalancer to automatically start serving on port 443

<placeholder for platform instructions>

## Parameters
Name          ~          Example Value
* `RABBIT_HOST` ~ localhost
* `RABBIT_PORT` ~ 5672
* `RABBIT_NAMESPACE` ~ username
* `RABBIT_USER` ~ guest
* `RABBIT_PASS` ~ guest
* `RABBIT_VHOST` ~ 

# Development environment
Make sure you have a `basic-auth` and `nest-tls-secret` secrets before running Cloud9!
```bash
root@my-vm:/home/ubuntu# kubectl get secret
NAME                  TYPE                                  DATA      AGE
basic-auth            Opaque                                1         4d
default-token-fsnqw   kubernetes.io/service-account-token   3         4d
cis-tls-secret        Opaque                                2         4d
```

## Build IDE
```bash
docker build -t bodom0015/cloud9-cis .
```

## Start IDE Container
To start Cloud9:
```bash
kubectl create -f cloud9.yaml
```

You can now access Cloud9 running at https://subdomain.my-hostname.org/ide.html

## Stop IDE Container
To stop Cloud9:
```bash
kubectl delete -f cloud9.yaml
```
