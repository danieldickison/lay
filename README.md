Looking at you.

Install rails gems locally, using brew-installed openssl for mysql native gem compilation ([https://stackoverflow.com/questions/39617761/cant-install-mysql2-gem-on-macos-sierra](ref)):
```
lay$ ./bin/bundle config --local build.mysql2 "--with-ldflags=-L/usr/local/opt/openssl/lib --with-cppflags=-I/usr/local/opt/openssl/include"
lay$ ./bin/bundle install --path vendor/cache
```

Initialize db:
```
$ mysql -u root
> CREATE DATABASE `lay_development`;
> ^d

lay$ ./bin/rails db:migrate RAILS_ENV=development
```

Setup files:
```
lay/config$ gpg gdrive-api.json.gpg (passphrase hint: Wickenburg pie)
lay/public$ ln -s ~/Dropbox/LAY_Proj_ContentShare/ lay
```

Run rails:
```
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
