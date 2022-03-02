# Motivation

Frontend developers sometimes need to test local generated JS files with remote API server. This is not easy without some customization work. In this example, we leverage the man-in-the-middle mechanism to achieve this.

### The request flow we planned
We plan to route all JS resource request to local nodejs server. All the other requests will goes to real server.
#### For real-time compiled JS resource
```mermaid

sequenceDiagram

participant browser
participant dns resolver
participant nginx@127.0.0.1
participant nodejs

browser->>dns resolver: example.com
dns resolver->>dns resolver: check /etc/hosts
dns resolver->>browser: 127.0.0.1

browser->>nginx@127.0.0.1: https://example.com/assets/index.js
nginx@127.0.0.1->>nginx@127.0.0.1: route /assets/* to https://nodejs:8443
nginx@127.0.0.1->>nodejs: https://example.com/assets/index.js
nodejs->>nginx@127.0.0.1: OK
nginx@127.0.0.1->>browser: OK
```
#### For all the other requests
```mermaid

sequenceDiagram

participant browser
participant dns resolver
participant nginx@127.0.0.1
participant example.com

browser->>dns resolver: example.com
dns resolver->>dns resolver: check /etc/hosts
dns resolver->>browser: 127.0.0.1

browser->>nginx@127.0.0.1: https://example.com/api/v1/users
nginx@127.0.0.1->>nginx@127.0.0.1: route non assets to https://93.184.216.34
nginx@127.0.0.1->>example.com: https://example.com/api/v1/users
example.com->>nginx@127.0.0.1: OK
nginx@127.0.0.1->>browser: OK
```

### Pre-condition
This example leverage [docker](https://docs.docker.com/engine/install/) and [docker-compose](https://docs.docker.com/compose/install/) to run.
### Step1. Generate self-signed certificate
Firstly, we need to generate a self-signed certificate to target domain.

```
./tool.sh GEN_CERT
```

Example input
```
Country Name (2 letter code) []:TW
State or Province Name (full name) []:TW
Locality Name (eg, city) []:Taipei
Organization Name (eg, company) []:Fake ExampleDotCom
Organizational Unit Name (eg, section) []:Fake UI team
Common Name (eg, fully qualified host name) []:example.com
Email Address []:
```
### Step2. Add DNS hook into /etc/hosts

```
127.0.0.1 example.com
```

### Step3. Start development environment

```
./tool.sh DEV_UP
```
### Test routing

Routed to nodejs
```
curl -k https://example.com/assets/xxx.js
```

You should get something like this
```
hello world from nodejs server
```

Routed to example.com
```
curl -k https://example.com/api/v1
```

You should see an html page like this
```
<!doctype html>
<html>
<head>
    <title>Example Domain</title>

    <meta charset="utf-8" />
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style type="text/css">
    body {
        background-color: #f0f0f2;
        margin: 0;
        padding: 0;
        font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", "Open Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;

    }
    div {
        width: 600px;
        margin: 5em auto;
        padding: 2em;
        background-color: #fdfdff;
        border-radius: 0.5em;
        box-shadow: 2px 3px 7px 2px rgba(0,0,0,0.02);
    }
    a:link, a:visited {
        color: #38488f;
        text-decoration: none;
    }
    @media (max-width: 700px) {
        div {
            margin: 0 auto;
            width: auto;
        }
    }
    </style>
</head>

<body>
<div>
    <h1>Example Domain</h1>
    <p>This domain is for use in illustrative examples in documents. You may use this
    domain in literature without prior coordination or asking for permission.</p>
    <p><a href="https://www.iana.org/domains/example">More information...</a></p>
</div>
</body>
</html>
```

### Customize your own route in config/route.conf

```
upstream actual_server_ssl_backend {
    # change this to your target domain IP
	server 93.184.216.34:443;
}

upstream nodejs_backend {
	server nodejs:8443;
}

server {
    listen              443 ssl;

    ssl_certificate     /etc/httpd/conf/ssl/cert.pem;
    ssl_certificate_key /etc/httpd/conf/ssl/key.pem;

    # change this to your target server domain
    server_name         example.com;

    # change routing pattern to nodejs
    location ~ ^/assets/.*$ {
    	proxy_set_header            Host $host;
    	proxy_pass                  https://nodejs_backend;
    }

    # the rest of routes will go back to actual server
    location / {
    	proxy_set_header            Host $host;
        proxy_pass                  https://actual_server_ssl_backend;
    }
}
```


### Add self-signed cert into trust store
This is the hardest part since modern browser blocked self-signed certificate. The workaround depends on the browser and version you use. Here are the [steps](https://www.enovision.net/google-chrome-access-using-self-signed-certificate-macos) you can try first.

Note: It seems Chrome can only accept self-signed certificate under incognito mode even after we add it to trust store.


### Clean up
To clean up everything. You should teardown the docker by following command.
```
./tool.sh DEV_DOWN
```

Remember to remove your changes in /etc/hosts
```
# 127.0.0.1 example
```