Looking at you.

Install rails gems locally, using brew-install openssl for mysql native gem compilation:
```
lay$ ./bin/bundle config --local build.mysql2 "--with-ldflags=-L/usr/local/opt/openssl/lib --with-cppflags=-I/usr/local/opt/openssl/include"
lay$ ./bin/bundle install --path vendor/cache
```

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
