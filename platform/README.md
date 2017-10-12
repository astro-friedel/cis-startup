# Crops in Silico Platform API / UI / IDE
See https://github.com/cropsinsilico

# Build
```bash
docker build -t bodom0015/cloud9-cis .
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

Then start up the Crops in Silico platform:
```bash
kubectl create -f loadbalancer.yaml,nest.yaml
```

To shut things down:
```bash
kubectl delete -f nest.yaml
```

## Parameters
Name          ~          Example Value
* `REDIS_HOST` ~ localhost
* `POSTGRES_HOST` ~ localhost

# Development environment
Make sure you have a `basic-auth` and `nest-tls-secret` secrets before running Cloud9!
```bash
root@my-vm:/home/ubuntu# kubectl get secret
NAME                  TYPE                                  DATA      AGE
basic-auth            Opaque                                1         4d
default-token-fsnqw   kubernetes.io/service-account-token   3         4d
cis-tls-secret       Opaque                                2         4d
```

To start Cloud9:
```bash
kubectl create -f cloud9.yaml
```

You can now access Cloud9 running at https://subdomain.my-hostname.org/ide.html

To stop Cloud9:
```bash
kubectl delete -f cloud9.yaml
```
