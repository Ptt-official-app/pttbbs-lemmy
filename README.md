# pttbbs-lemmy

This repo is a workaround for [pttbbs-backend](https://github.com/Ptt-official-app/pttbbs-backend) to acces [Lemmy](https://github.com/LemmyNet/lemmy) authentication.

Currently, it allows:
1. lets callers with an admin token generate tokens for any user.

## Getting Started

With [docker](https://www.docker.com/) and [`cargo`](https://doc.rust-lang.org/cargo/getting-started/installation.html) installed, you can start `pttbbs-lemmy` with:

```sh
git clone git@github.com:Ptt-official-app/pttbbs-lemmy.git
cd pttbbs-lemmy
git submodule update --init --recursive

./scripts/lemmy_docker_build_all.sh
./scripts/start-getting-started.sh
```

You should be able to:
1. Login with `SYSOP/1234567890` at [http://localhost:1234](http://localhost:1234)
2.
```sh
curl -X POST -H 'Content-Type: application/json' -d '{"username_or_email": "SYSOP", "password": "1234567890", "stay_logged_in": true}' 'http://localhost:8536/api/v4/account/auth/login'

jwt=${jwt} curl -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer ${jwt}" -d '{"username": "SYSOP"}' 'http://localhost:8537/api/v4/pttbbs-lemmy/token'
```

If you want to clean up the docker containers:

```sh
./scripts/stop-getting-started.sh
```
