Looking at you.

Run rails:
```
lay/config$ gpg gdrive-api.json.gpg (passphrase hint: Wickenburg pie)
lay/public$ ln -s ~/Dropbox/LAY_Proj_ContentShare/ lay
lay/bin$ rails server
```

Run nginx:
```
lay/bin$ ./install-nginx
$ nginx
$ tail -f /usr/local/var/log/nginx/*.log
```

Run ntpd:
```
$ sudo ntpd -n
```
