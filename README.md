# alpine-nginx

nginx docker image prepared to act as a
 
 - static file server
 - reverse proxy server for application server
   - hit miss cache server for the reverse proxy
   - SNI TLS termination at reverse proxy with 
    - everything over TLS port redirection
    - routing to application server via domain name
 - certs renewal via ACME dir

